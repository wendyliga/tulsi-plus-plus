// Copyright 2016 The Tulsi Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation


// Provides methods utilizing Bazel query (http://bazel.build/docs/query.html) to extract
// information from a workspace.
final class BazelQueryInfoExtractor {

  enum ExtractorError: Error {
    /// A valid Bazel binary could not be located.
    case invalidBazelPath
  }

  /// The location of the bazel binary.
  var bazelURL: URL
  /// The location of the directory in which the workspace enclosing this BUILD file can be found.
  let workspaceRootURL: URL

  private let localizedMessageLogger: LocalizedMessageLogger
  private var queuedInfoMessages = [String]()

  private typealias CompletionHandler = (Process, Data, String?, String) -> Void

  init(bazelURL: URL, workspaceRootURL: URL, localizedMessageLogger: LocalizedMessageLogger) {
    self.bazelURL = bazelURL
    self.workspaceRootURL = workspaceRootURL
    self.localizedMessageLogger = localizedMessageLogger
  }

  func extractTargetRulesFromPackages(_ packages: [String]) -> [RuleInfo] {
    guard !packages.isEmpty else {
      return []
    }

    let profilingStart = localizedMessageLogger.startProfiling("fetch_rules",
                                                               message: "Fetching rules for packages \(packages)")
    var infos = [RuleInfo]()
    let query = packages.map({ "kind(rule, \($0):all)"}).joined(separator: "+")
    do {
      let (task, data, stderr, debugInfo) = try self.bazelSynchronousQueryTask(query, outputKind: "xml")
      if task.terminationStatus != 0 {
        showExtractionError(debugInfo, stderr: stderr, displayLastLineIfNoErrorLines: true)
      } else if let entries = self.extractRuleInfosFromBazelXMLOutput(data) {
        infos = entries
      }
    } catch {
      // The error has already been displayed to the user.
      return []
    }

    localizedMessageLogger.logProfilingEnd(profilingStart)
    return infos
  }

  /// Extracts a map of RuleInfo to considered expansions for the given test_suite targets.
  // The information provided represents the full possible set of tests for each test_suite; the
  // actual expansion by Bazel may not include all of the returned labels and will be done
  // recursively such that a test_suite whose expansion contains another test_suite would expand to
  // the contents of the incldued suite.
  func extractTestSuiteRules(_ testSuiteLabels: [BuildLabel]) -> [RuleInfo: Set<BuildLabel>] {
    if testSuiteLabels.isEmpty { return [:] }
    let profilingStart = localizedMessageLogger.startProfiling("expand_test_suite_rules",
                                                               message: "Expanding \(testSuiteLabels.count) test suites")

    var infos = [RuleInfo: Set<BuildLabel>]()
    let labelDeps = testSuiteLabels.map {"deps(\($0.value))"}
    let joinedLabelDeps = labelDeps.joined(separator: "+")
    let query = "kind(\"test_suite rule\",\(joinedLabelDeps))"
    do {
      let (_, data, _, debugInfo) = try self.bazelSynchronousQueryTask(query,
                                                                       outputKind: "xml",
                                                                       additionalArguments: ["--keep_going"])
      if let entries = self.extractRuleInfosWithRuleInputsFromBazelXMLOutput(data) {
        infos = entries
      }
      // Note that this query is expected to return a non-zero exit code on occasion, so no error
      // message is logged.
      localizedMessageLogger.infoMessage(debugInfo)
      localizedMessageLogger.logProfilingEnd(profilingStart)
    } catch {
      // The error has already been displayed to the user.
      return [:]
    }
    return infos
  }

  /// Extracts all of the transitive BUILD and skylark (.bzl) files used by the given targets.
  func extractBuildfiles<T: Collection>(_ targets: T) -> Set<BuildLabel> where T.Iterator.Element == BuildLabel {
    if targets.isEmpty { return Set() }

    let profilingStart = localizedMessageLogger.startProfiling("extracting_skylark_files",
                                                               message: "Finding Skylark files for \(targets.count) rules")

    let labelDeps = targets.map {"deps(\($0.value))"}
    let joinedLabelDeps = labelDeps.joined(separator: "+")
    let query = "buildfiles(\(joinedLabelDeps))"
    let buildFiles: Set<BuildLabel>
    do {
      // Errors in the BUILD structure being examined should not prevent partial extraction, so this
      // command is considered successful if it returns any valid data at all.
      let (_, data, _, debugInfo) = try self.bazelSynchronousQueryTask(query,
                                                                       outputKind: "xml",
                                                                       additionalArguments: ["--keep_going"])
      // TODO(b/64979751): Stream this debugInfo to a file.
      self.queuedInfoMessages.append(debugInfo)

      if let labels = extractSourceFileLabelsFromBazelXMLOutput(data) {
        buildFiles = Set(labels)
      } else {
        localizedMessageLogger.warning("BazelBuildfilesQueryFailed",
                                       comment: "Bazel 'buildfiles' query failed to extract information.")
        buildFiles = Set()
      }

      localizedMessageLogger.logProfilingEnd(profilingStart)
    } catch {
      // Error will be displayed at the end of project generation.
      return Set()
    }

    return buildFiles
  }

  // MARK: - Private methods

  private func showExtractionError(_ debugInfo: String,
                                   stderr: String?,
                                   displayLastLineIfNoErrorLines: Bool = false) {
    localizedMessageLogger.infoMessage(debugInfo)
    let details: String?
    if let stderr = stderr {
      if displayLastLineIfNoErrorLines {
        details = BazelErrorExtractor.firstErrorLinesOrLastLinesFromString(stderr)
      } else {
        details = BazelErrorExtractor.firstErrorLinesFromString(stderr)
      }
    } else {
      details = nil
    }
    localizedMessageLogger.error("BazelInfoExtractionFailed",
                                 comment: "Error message for when a Bazel extractor did not complete successfully. Details are logged separately.",
                                 details: details)
  }

  // Generates an NSTask that will perform a bazel query, capturing the output data and passing it
  // to the terminationHandler.
  private func bazelQueryTask(_ query: String,
                              outputKind: String? = nil,
                              additionalArguments: [String] = [],
                              message: String = "",
                              terminationHandler: @escaping CompletionHandler) throws -> Process {
    guard FileManager.default.fileExists(atPath: bazelURL.path) else {
      localizedMessageLogger.error("BazelBinaryNotFound",
                                   comment: "Error to show when the bazel binary cannot be found at the previously saved location %1$@.",
                                   values: bazelURL as NSURL)
      throw ExtractorError.invalidBazelPath
    }

    var arguments = [
        "--max_idle_secs=60",
        "query",
        "--announce_rc",  // Print the RC files used by this operation.
        "--noimplicit_deps",
        "--order_output=no",
        "--noshow_loading_progress",
        "--noshow_progress",
        query
    ]
    arguments.append(contentsOf: additionalArguments)
    if let kind = outputKind {
      arguments.append(contentsOf: ["--output", kind])
    }

    var message = message
    if message != "" {
      message = "\(message)\n"
    }
    localizedMessageLogger.infoMessage("\(message)Running \(bazelURL.path) with arguments: \(arguments)")

    let task = TulsiTaskRunner.createTask(bazelURL.path, arguments: arguments) {
      completionInfo in
        let debugInfoFormatString = NSLocalizedString("DebugInfoForBazelCommand",
                                                      bundle: Bundle(for: type(of: self)),
                                                      comment: "Provides general information about a Bazel failure; a more detailed error may be reported elsewhere. The Bazel command is %1$@, exit code is %2$d, stderr %3$@.")
        let stderr = NSString(data: completionInfo.stderr, encoding: String.Encoding.utf8.rawValue)
        let debugInfo = String(format: debugInfoFormatString,
                               completionInfo.commandlineString,
                               completionInfo.terminationStatus,
                               stderr ?? "<No STDERR>")

      terminationHandler(completionInfo.task,
                         completionInfo.stdout,
                         stderr as String?,
                         debugInfo)
    }

    return task
  }

  /// Performs the given Bazel query synchronously in the workspaceRootURL directory.
  private func bazelSynchronousQueryTask(_ query: String,
                                         outputKind: String? = nil,
                                         additionalArguments: [String] = [],
                                         message: String = "") throws -> (bazelTask: Process,
                                                                          returnedData: Data,
                                                                          stderrString: String?,
                                                                          debugInfo: String) {
    let semaphore = DispatchSemaphore(value: 0)
    var data: Data! = nil
    var stderr: String? = nil
    var info: String! = nil

    let task = try bazelQueryTask(query,
                                  outputKind: outputKind,
                                  additionalArguments: additionalArguments,
                                  message: message) {
      (_: Process, returnedData: Data, stderrString: String?, debugInfo: String) in
        data = returnedData
        stderr = stderrString
        info = debugInfo
      semaphore.signal()
    }

    task.currentDirectoryPath = workspaceRootURL.path
    task.launch()

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    return (task, data, stderr, info)
  }

  private func extractRuleInfosWithRuleInputsFromBazelXMLOutput(_ bazelOutput: Data) -> [RuleInfo: Set<BuildLabel>]? {
    do {
      var infos = [RuleInfo: Set<BuildLabel>]()
      let doc = try XMLDocument(data: bazelOutput, options: 0)
      let rules = try doc.nodes(forXPath: "/query/rule")
      for ruleNode in rules {
        guard let ruleElement = ruleNode as? XMLElement else {
          localizedMessageLogger.error("BazelResponseXMLNonElementType",
                                       comment: "General error to show when the XML parser returns something other " +
                                               "than an NSXMLElement. This should never happen in practice.")
          continue
        }
        guard let ruleLabel = ruleElement.attribute(forName: "name")?.stringValue else {
          localizedMessageLogger.error("BazelResponseMissingRequiredAttribute",
                                       comment: "Bazel response XML element %1$@ was found but was missing an attribute named %2$@.",
                                       values: ruleElement, "name")
          continue
        }
        guard let ruleType = ruleElement.attribute(forName: "class")?.stringValue else {
          localizedMessageLogger.error("BazelResponseMissingRequiredAttribute",
                                       comment: "Bazel response XML element %1$@ was found but was missing an attribute named %2$@.",
                                       values: ruleElement, "class")
          continue
        }

        func extractLabelsFromXpath(_ xpath: String) throws -> Set<BuildLabel> {
          var labelSet = Set<BuildLabel>()
          let nodes = try ruleElement.nodes(forXPath: xpath)
          for node in nodes {
            guard let label = node.stringValue else {
              localizedMessageLogger.error("BazelResponseLabelAttributeInvalid",
                                           comment: "Bazel response XML element %1$@ should have a valid string value but does not.",
                                           values: node)
              continue
            }
            labelSet.insert(BuildLabel(label))
          }
          return labelSet
        }

        // Retrieve the list of linked targets through the xctest_app (for ios_test) and test_host
        // (for apple_unit_test and apple_ui_test). This provides a link between the test target and
        // the test host so they can be linked in Xcode.
        var linkedTargetLabels = Set<BuildLabel>()
        for attribute in ["xctest_app", "test_host"] {
          linkedTargetLabels.formUnion(
              try extractLabelsFromXpath("./label[@name='\(attribute)']/@value"))
        }

        let entry = RuleInfo(label: BuildLabel(ruleLabel),
                             type: ruleType,
                             linkedTargetLabels: linkedTargetLabels)

        infos[entry] = try extractLabelsFromXpath("./rule-input/@name")
      }
      return infos
    } catch let e as NSError {
      localizedMessageLogger.error("BazelResponseXMLParsingFailed",
                                   comment: "Extractor Bazel output failed to be parsed as XML with error %1$@. This may be a Bazel bug or a bad BUILD file.",
                                   values: e.localizedDescription)
      return nil
    }
  }

  private func extractRuleInfosFromBazelXMLOutput(_ bazelOutput: Data) -> [RuleInfo]? {
    if let infoMap = extractRuleInfosWithRuleInputsFromBazelXMLOutput(bazelOutput) {
      return [RuleInfo](infoMap.keys)
    }
    return nil
  }

  private func extractSourceFileLabelsFromBazelXMLOutput(_ bazelOutput: Data) -> Set<BuildLabel>? {
    do {
      let doc = try XMLDocument(data: bazelOutput, options: 0)
      let fileLabels = try doc.nodes(forXPath: "/query/source-file/@name")
      var extractedLabels = Set<BuildLabel>()
      for labelNode in fileLabels {
        guard let value = labelNode.stringValue else {
          localizedMessageLogger.error("BazelResponseLabelAttributeInvalid",
                                       comment: "Bazel response XML element %1$@ should have a valid string value but does not.",
                                       values: labelNode)
          continue
        }
        extractedLabels.insert(BuildLabel(value))
      }
      return extractedLabels
    } catch let e as NSError {
      localizedMessageLogger.error("BazelResponseXMLParsingFailed",
                                   comment: "Extractor Bazel output failed to be parsed as XML with error %1$@. This may be a Bazel bug or a bad BUILD file.",
                                   values: e.localizedDescription)
      return nil
    }
  }

  func logQueuedInfoMessages() {
    guard !self.queuedInfoMessages.isEmpty else {
      return
    }
    localizedMessageLogger.infoMessage("Log of Bazel query output follows:")
    for message in self.queuedInfoMessages {
      localizedMessageLogger.infoMessage(message)
    }
    self.queuedInfoMessages.removeAll()
  }
}
