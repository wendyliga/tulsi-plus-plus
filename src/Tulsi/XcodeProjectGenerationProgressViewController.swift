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

import Cocoa
import TulsiGenerator


/// Models a Tulsi generator action whose progress should be monitored.
class ProgressItem: NSObject {
  @objc dynamic let label: String
  @objc dynamic let maxValue: Int
  @objc dynamic var value: Int
  @objc dynamic var indeterminate: Bool

  init(notifier: AnyObject?, values: [AnyHashable: Any]) {
    let taskName = values[ProgressUpdatingTaskName] as! String
    label = NSLocalizedString(taskName,
                              value: taskName,
                              comment: "User friendly version of \(taskName)")
    maxValue = values[ProgressUpdatingTaskMaxValue] as! Int
    value = 0
    indeterminate = values[ProgressUpdatingTaskStartIndeterminate] as? Bool ?? false

    super.init()

    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self,
                                   selector: #selector(ProgressItem.progressUpdate(_:)),
                                   name: NSNotification.Name(rawValue: ProgressUpdatingTaskProgress),
                                   object: notifier)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  @objc func progressUpdate(_ notification: Notification) {
    indeterminate = false
    if let newValue = notification.userInfo?[ProgressUpdatingTaskProgressValue] as? Int {
      value = newValue
    }
  }
}


/// Handles generation of an Xcode project and displaying progress.
class XcodeProjectGenerationProgressViewController: NSViewController {
  @objc dynamic var progressItems = [ProgressItem]()

  weak var outputFolderOpenPanel: NSOpenPanel? = nil

  var removePreviousProject: Bool = true
  var outputFolderURL: URL? = nil

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self,
                                   selector: #selector(XcodeProjectGenerationProgressViewController.progressUpdatingTaskDidStart(_:)),
                                   name: NSNotification.Name(rawValue: ProgressUpdatingTaskDidStart),
                                   object: nil)
  }

  // Extracts source paths for selected source rules, generates a PBXProject and opens it.
  func generateProjectForConfigName(
    _ name: String,
    removePreviousProject: Bool,
    customOutputPath: URL? = nil,
    completionHandler: @escaping (_ projectURL: URL?,_ outputPath: URL?) -> Void
  ) {
    assert(view.window != nil, "Must not be called until after the view controller is presented.")
    self.removePreviousProject = removePreviousProject
    self.outputFolderURL = customOutputPath
    
    if outputFolderURL == nil {
      showOutputFolderPicker() { (url: URL?) in
        guard let url = url else {
          completionHandler(nil, nil)
          return
        }
        self.outputFolderURL = url
        self.generateProjectForConfigName(
          name,
          removePreviousProject: removePreviousProject,
          customOutputPath: url,
          completionHandler: completionHandler
        )
      }
      return
    }

    generateXcodeProjectForConfigName(name) { [weak self] (projectURL: URL?) in
      completionHandler(projectURL, self?.outputFolderURL)
    }
  }

  @objc func progressUpdatingTaskDidStart(_ notification: Notification) {
    guard let values = notification.userInfo else {
      assertionFailure("Progress task notification received without parameters.")
      return
    }
    progressItems.append(ProgressItem(notifier: notification.object as AnyObject?, values: values))
  }

  // MARK: - Private methods

  private func showOutputFolderPicker(_ completionHandler: @escaping (URL?) -> Void) {
    let panel = NSOpenPanel()
    panel.title = NSLocalizedString("ProjectGeneration_SelectProjectOutputFolderTitle",
                                    comment: "Title for open panel through which the user should select where to generate the Xcode project.")
    panel.message = NSLocalizedString("ProjectGeneration_SelectProjectOutputFolderMessage",
                                      comment: "Message to show at the top of the Xcode output folder sheet, explaining what to do.")

    panel.prompt = NSLocalizedString("ProjectGeneration_SelectProjectOutputFolderAndGeneratePrompt",
                                     comment: "Label for the button used to confirm the selected output folder for the generated Xcode project which will also start generating immediately.")
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.canChooseFiles = false
    panel.beginSheetModal(for: view.window!) {
      let url: URL?
      if $0 == NSApplication.ModalResponse.OK {
        url = panel.url
        
        if let document = self.representedObject as? TulsiProjectDocument {
          document.updateChangeCount(.changeDone)
          // trigger save document
          NSApp.sendAction(#selector(NSDocument.save(_:)), to: nil, from: self)
        }
      } else {
        url = nil
      }
      completionHandler(url)
    }
  }

  /// Asynchronously generates an Xcode project, invoking the given completionHandler on the main
  /// thread with an URL to the generated project (or nil to indicate failure).
  private func generateXcodeProjectForConfigName(_ name: String, completionHandler: @escaping ((URL?) -> Void)) {
    let document = self.representedObject as! TulsiProjectDocument
    guard let workspaceRootURL = document.workspaceRootURL else {
      LogMessage.postError(NSLocalizedString("Error_BadWorkspace",
                                             comment: "General error when project does not have a valid Bazel workspace."))
      Thread.doOnMainQueue() {
        completionHandler(nil)
      }
      return
    }
    guard let concreteOutputFolderURL = outputFolderURL else {
      // This should never actually happen and indicates an unexpected path through the UI.
      LogMessage.postError(NSLocalizedString("Error_NoOutputFolder",
                                             comment: "Error for a generation attempt without a valid target output folder"))
      LogMessage.displayPendingErrors()
      Thread.doOnMainQueue() {
        completionHandler(nil)
      }
      return
    }

    guard let configDocument = getConfigDocumentNamed(name) else {
      // Error messages have already been displayed.
      completionHandler(nil)
      return
    }
    
    func ending() {
      Thread.doOnQOSUserInitiatedThread() {
        let url = configDocument.generateXcodeProjectInFolder(concreteOutputFolderURL,
                                                              withWorkspaceRootURL: workspaceRootURL)
        Thread.doOnMainQueue() {
          completionHandler(url)
        }
      }
    }
    
    if let projectName = configDocument.projectName {
      let projectPath = concreteOutputFolderURL.appendingPathComponent(projectName + ".xcodeproj")
      
      delete(previousProject: projectPath) {
        ending()
      }
    } else {
      ending()
    }
  }
  
  private func delete(previousProject path: URL, completion: @escaping () -> Void) {
    guard removePreviousProject else { return completion() }
    let maxProgress = 1
    progressItems.append(ProgressItem(
      // so it will become unique, and other notification center will no distrub this process
      notifier: nil,
      values: [
        ProgressUpdatingTaskName: "Delete Previous Project",
        ProgressUpdatingTaskMaxValue: maxProgress,
        ProgressUpdatingTaskStartIndeterminate: false
      ]
    ))
    
    func completeProgress() {
      progressItems.first(where: { $0.label == "Delete Previous Project" })?.value = maxProgress
    }
    
    Thread.doOnQOSUserInitiatedThread {
      guard FileManager.default.fileExists(atPath: path.path) else {
        Thread.doOnMainQueue {
          LogMessage.postInfo("No previous project detected")
          completeProgress()
          completion()
        }
        return
      }
      
      do {
        try FileManager.default.removeItem(at: path)
        LogMessage.postInfo("\(path.path) is removed")
        
        Thread.doOnMainQueue {
          completeProgress()
          completion()
        }
      } catch {
        // if error happend, we still continue the generate process.
        LogMessage.postWarning(NSLocalizedString(
          "Error_DeletePreviousProject",
          comment: "Fail to delete previous project at \(path.path)"
        ))

        Thread.doOnMainQueue {
          completeProgress()
          completion()
        }
      }
    }
  }

  /// Loads a previously created config with the given name as a sparse document.
  private func getConfigDocumentNamed(_ name: String) -> TulsiGeneratorConfigDocument? {
    let document = self.representedObject as! TulsiProjectDocument

    let errorInfo: String
    do {
      return try document.loadSparseConfigDocumentNamed(name)
    } catch TulsiProjectDocument.DocumentError.noSuchConfig {
      errorInfo = "No URL for config named '\(name)'"
    } catch TulsiProjectDocument.DocumentError.configLoadFailed(let info) {
      errorInfo = info
    } catch TulsiProjectDocument.DocumentError.invalidWorkspace(let info) {
      errorInfo = "Invalid workspace: \(info)"
    } catch {
      errorInfo = "An unexpected exception occurred while loading config named '\(name)'"
    }

    let msg = NSLocalizedString("Error_GeneralProjectGenerationFailure",
                                comment: "A general, critical failure during project generation.")
    LogMessage.postError(msg, details: errorInfo)
    LogMessage.displayPendingErrors()
    return nil
  }
}
