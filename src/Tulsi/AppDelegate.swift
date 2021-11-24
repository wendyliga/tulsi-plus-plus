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
import Sparkle


final class AppDelegate: NSObject, NSApplicationDelegate {
  @IBOutlet var checkForUpdatesMenuItem: NSMenuItem!
  
  let updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
  var splashScreenWindowController: SplashScreenWindowController! = nil

  @IBAction func openSourceLicense(_ sender: NSMenuItem) {
    let window = OpenSourceLicenseWindowController()
    window.showWindow(self)
  }
  
  @IBAction func openChangelogs(_ sender: NSMenuItem) {
    NSWorkspace.shared.open(URL(string: "https://github.com/wendyliga/tulsi-plus-plus/blob/main/CHANGELOG.md")!)
  }
  
  @IBAction func fileBugReport(_ sender: NSMenuItem) {
    BugReporter.fileBugReport()
  }

  // MARK: - NSApplicationDelegate

  func applicationWillFinishLaunching(_ notification: Notification) {
    // Create the shared document controller.
    let _ = TulsiDocumentController()

    let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    LogMessage.postSyslog("Tulsi UI: version \(version)")
    
    // config updater
    updaterController.updater.automaticallyChecksForUpdates = true
    updaterController.updater.updateCheckInterval = TimeInterval(24 * 60 * 60) // 1 day
      
    #if ARM64
    updaterController.updater.setFeedURL(URL(string: "https://raw.githubusercontent.com/wendyliga/tulsi-plus-plus/main/appcast_apple_silicon.xml"))
    #else
    updaterController.updater.setFeedURL(URL(string: "https://raw.githubusercontent.com/wendyliga/tulsi-plus-plus/main/appcast.xml"))
    #endif
    
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    splashScreenWindowController = SplashScreenWindowController()
    splashScreenWindowController.showWindow(self)
    
    // start updater
    checkForUpdatesMenuItem.target = updaterController
    checkForUpdatesMenuItem.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
    updaterController.startUpdater()
    
    // check on startup
    updaterController.updater.checkForUpdatesInBackground()
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    return false
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
