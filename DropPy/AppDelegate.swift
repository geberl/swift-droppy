//
//  AppDelegate.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON
import os.log


// Logger configuration.
let logGeneral = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "general")
let logUpdate = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "update")
let logLicense = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "license")
let logFileSystem = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "filesystem")
let logDrop = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "drop")
let logExecution = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "execution")
let logUi = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "ui")


// Global application state object.
struct AppState {
    static var allWorkflows = [String: Dictionary<String, String>]()
    
    static var activeName: String? = nil
    static var activeInterpreterName: String? = nil
    static var activeJsonFile: String? = nil
    static var activeLogoFile: String? = nil
    static var tempDirPath: String? = nil
    
    static var interpreterStockName: String = "macOS pre-installed"
    static var bundledWorkspaceVersion: String = "v2.0 (6558798) (2017-12-23)"
    static var bundledRunVersion: String = "v2.0 (c5c07dc) (2017-12-21)"
    
    static var initialSetupCompleted: Bool = false
    static var trialStartSalt: String = "nBL4QzmKbk8vhnfke9uvNHRDUtwkoPvJ"
    
    static var isLicensed: Bool = false
    static var isInTrial: Bool = false
    static var regTrialStatus: String = "Unlicensed (Trial)"
    
    static var systemVersion = ProcessInfo.processInfo.operatingSystemVersion
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let userDefaults = UserDefaults.standard

    var executionInProgress: Bool = false
    
    @IBAction func onNewWorkflowMenuItem(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: .workflowNew, object: nil)
    }
    
    @IBAction func onEditWorkflowMenuItem(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: .workflowEdit, object: nil)
    }
    
    @IBAction func onDeleteWorkflowMenuItem(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: .workflowDelete, object: nil)
    }
    
    @IBAction func onOpenWorkspaceMenuItem(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: .workflowDirOpen, object: nil)
    }
    
    @IBOutlet weak var devModeMenuItem: NSMenuItem!
    
    @IBAction func onDevModeMenuItem(_ sender: NSMenuItem) {
        if self.userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) {
            self.userDefaults.set(false, forKey: UserDefaultStruct.devModeEnabled)
        } else {
            self.userDefaults.set(true, forKey: UserDefaultStruct.devModeEnabled)
        }
        
        self.loadDevMenuState()
        NotificationCenter.default.post(name: .devModeChanged, object: nil)
    }
    
    func loadDevMenuState() {
        if self.userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) {
            self.devModeMenuItem.state = NSControl.StateValue.on
        } else {
            self.devModeMenuItem.state = NSControl.StateValue.off
        }
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if AppState.tempDirPath != nil {
            if isDir(path: AppState.tempDirPath!) {
                removeDir(path: AppState.tempDirPath!)
            }
        }
        return NSApplication.TerminateReply.terminateNow
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.reloadWorkflows),
                                               name: .reloadWorkflows, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.startPythonExecutor),
                                               name: .droppingConcluded, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewInterpreter),
                                               name: .interpreterNotFound, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewEditor),
                                               name: .editorNotFound, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewWorkspace),
                                               name: .workspaceNotFound, object: nil)
        
        self.devModeMenuItem.isEnabled = true  // override auto enabling in "Workflow" menu for this item.
        
        AppState.initialSetupCompleted = !isFirstRun()
        if AppState.initialSetupCompleted {
            reapplyPrefs()
            loadWindowPosition()
            self.loadDevMenuState()
            
            AppState.isLicensed = isLicensed()
            if !AppState.isLicensed {
                os_log("No license information found.", log: logLicense, type: .info)
                AppState.isInTrial = isInTrial()
            }
            
            if !AppState.isInTrial && !AppState.isLicensed {
                self.registrationWindowController.showWindow(self)
            }
            
            autoUpdate() // no checking for updates on the first start, the second launch is soon enough.
        } else {
            self.showSetupAssistant()
            
            if AppState.initialSetupCompleted {
                beginTrial()  // Trial period only starts once the initial setup has been completed successfully.
                reapplyPrefs()  // Initialize the rest of the preferences with their default values.
                NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
            }
        }
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        if AppState.initialSetupCompleted {
            self.reloadWorkflowsFromDir()
        }
    }
    
    @objc func reloadWorkflows(_ notification: Notification) {
        self.reloadWorkflowsFromDir()
    }

    func checkInterpreterInfo() -> (String?, String?) {
        let userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        if let activeInterpreterName: String = AppState.activeInterpreterName {
            if let interpreterInfo: Dictionary<String, String> = userDefaultInterpreters[activeInterpreterName] {
                let executablePath = interpreterInfo["executable"]!
                let executableArgs = interpreterInfo["arguments"]!
                if isFile(path: executablePath) {
                    return (executablePath, executableArgs)
                }
            }
        }
        NotificationCenter.default.post(name: .interpreterNotFound, object: nil)
        return (nil, nil)
    }
    
    @objc func startPythonExecutor(_ notification: Notification) {
        // Show registration window with open purchase sheet to user on each drop.
        // At this moment do not refuse executing, maybe later in 2.0.
        if !AppState.isLicensed {
            AppState.isInTrial = isInTrial()  // Recheck if trial period expired in the meantime.
            if !AppState.isInTrial {
                self.registrationWindowController.showWindow(self)
                NotificationCenter.default.post(name: .reopenPurchaseSheet, object: nil)
            }
        }
        
        guard let tempDirPath: String = AppState.tempDirPath else {
            NotificationCenter.default.post(name: .executionFinished, object: nil)
            return
        }
        guard let workflowFile: String = AppState.activeJsonFile else {
            NotificationCenter.default.post(name: .executionFinished, object: nil)
            return
        }
        let workspacePath = checkWorkspaceInfo()
        let (executablePath, executableArgs) = self.checkInterpreterInfo()
        if (workspacePath == nil) || (executablePath == nil) || (executableArgs == nil) {
            NotificationCenter.default.post(name: .executionFinished, object: nil)
            return
        }
        
        // The notification that starts this function is sometimes sent (or received?) twice.
        // Using a boolean class variable as a workaround prevents multiple instantiation of PythonExecutor.
        if !self.executionInProgress {
            self.executionInProgress = true
            
            // Usually doesn't appear on screen, because the steps until the first Task is executed happen so fast.
            let statusDict: [String: String] = ["text": "Preparing"]
            NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
            
            var timestampDirPath: String = ""
            var exitCode: Int = 0
            
            DispatchQueue.global(qos: .background).async {
                let pythonExecutor = PythonExecutor(tempDirPath: tempDirPath,
                                                    workflowFile: workflowFile,
                                                    workspacePath: workspacePath!,
                                                    executablePath: executablePath!,
                                                    executableArgs: executableArgs!)
                pythonExecutor.run()
                (timestampDirPath, exitCode) = pythonExecutor.evaluate()
                
                DispatchQueue.main.async {
                    self.endPythonExecutor(timestampDirPath: timestampDirPath, exitCode: exitCode)
                }
            }
        }
    }
    
    func endPythonExecutor(timestampDirPath: String, exitCode: Int) {
        self.executionInProgress = false

        let pathDict:[String: String] = ["timestampDirPath": timestampDirPath,
                                         "exitCode": String(exitCode)]
        NotificationCenter.default.post(name: .executionFinished, object: nil, userInfo: pathDict)
        
        os_log("Execution finished.", log: logExecution, type: .debug)
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ application: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window: AnyObject in application.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }
    
    lazy var preferencesWindowController: WindowControllerPrefs  = {
        let wcSb = NSStoryboard(name: NSStoryboard.Name(rawValue: "Preferences"), bundle: Bundle.main)
        return wcSb.instantiateInitialController() as! WindowControllerPrefs
    }()
    
    @IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
        self.preferencesWindowController.showWindow(self)
    }
    
    @objc func setNewInterpreter(_ notification: Notification) {
        self.preferencesWindowController.showWindow(self)
        
        var informativeText: String = "The interpreter "
        if let activeInterpreterName = AppState.activeInterpreterName {
            informativeText += "'" + activeInterpreterName + "' "
        }
        informativeText += "can't be found.\n\n"
        informativeText += "Please (re-) create it here or set a different interpreterName in the Workflow."
        self.preferencesWindowController.switchToPrefTab(index: 1,
                                                         messageText: "Interpreter not found",
                                                         informativeText: informativeText)
    }
    
    @objc func setNewEditor(_ notification: Notification) {
        self.preferencesWindowController.showWindow(self)

        var informativeText: String = "Your previously selected external text editor can't be found any more.\n\n"
        informativeText += "Please adjust your settings."
        self.preferencesWindowController.switchToPrefTab(index: 2,
                                                         messageText: "Editor not found",
                                                         informativeText: informativeText)
    }
    
    @objc func setNewWorkspace(_ notification: Notification) {
        self.preferencesWindowController.showWindow(self)
        
        var informativeText: String = "The Workspace folder can't be found.\n\n"
        informativeText += "Please adjust your settings."
        self.preferencesWindowController.switchToPrefTab(index: 3,
                                                         messageText: "Workspace not found",
                                                         informativeText: informativeText)
    }
    
    lazy var registrationWindowController: WindowControllerRegistration  = {
        let wcSb = NSStoryboard(name: NSStoryboard.Name(rawValue: "Registration"), bundle: Bundle.main)
        return wcSb.instantiateInitialController() as! WindowControllerRegistration
    }()
    
    @IBAction func showRegistrationWindow(_ sender: NSMenuItem) {
        self.registrationWindowController.showWindow(self)
    }
    
    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        manualUpdate(silent: false)
    }
    
    @IBAction func showReleaseNotes(_ sender: NSMenuItem) {
        if let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            openWebsite(webUrl: droppyappUrls.releaseNotes?.appendingPathComponent(versionNumber))
        } else {
            openWebsite(webUrl: droppyappUrls.releaseNotes)
        }
    }
    
    @IBAction func showDocumentation(_ sender: NSMenuItem) {
        openWebsite(webUrl: droppyappUrls.docs)
    }
    
    @IBAction func showSupport(_ sender: NSMenuItem) {
        openWebsite(webUrl: droppyappUrls.support)
    }
    
    @IBAction func showPrivacyStatement(_ sender: NSMenuItem) {
        openWebsite(webUrl: droppyappUrls.privacy)
    }
    
    @IBAction func showProductWebsite(_ sender: NSMenuItem) {
        openWebsite(webUrl: droppyappUrls.main)
    }
    
    lazy var firstRunWindowController: WindowControllerFirstRun  = {
        let wcSB = NSStoryboard(name: NSStoryboard.Name(rawValue: "FirstRun"), bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerFirstRun
    }()
    
    @IBAction func showFirstRunWindow(_ sender: NSMenuItem) {
        self.showSetupAssistant()
    }
    
    func showSetupAssistant() {
        // Set the Workspace and extract the default content via this assistant.
        if let windowFirstRun = firstRunWindowController.window {
            let application = NSApplication.shared
            // Use a modal window so the user can not access DropPy before going though with the initial setup.
            application.runModal(for: windowFirstRun)
            windowFirstRun.close()
            
            // Exit DropPy completely if the initial setup was cancelled before a workspaceDir was set.
            if !AppState.initialSetupCompleted {
                NSApplication.shared.terminate(self)
            }
        }
    }
    
    func reloadWorkflowsFromDir() {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        let workflowPath: String = workspacePath + "Workflows"
        os_log("Reloading Workflows from '%@'.", log: logGeneral, type: .debug, workflowPath)
        
        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: workflowPath)!
        
        var workflowsTemp = [String: Dictionary<String, String>]()
        
        while let element = enumerator.nextObject() as? String {
            if element.lowercased().hasSuffix(".json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath + "/" + element),
                                        options: .alwaysMapped)
                    let jsonObj = JSON(data: data)
                    if jsonObj != JSON.null {
                        let workflowName = jsonObj["name"].stringValue
                        let workflowImage = jsonObj["image"].stringValue
                        let workflowFile = element
                        let workflowInterpreterName = jsonObj["interpreterName"].stringValue
                        
                        // Make sure the same name is already used by another Workflow.
                        if workflowsTemp[workflowName] == nil {
                            workflowsTemp[workflowName] = [String: String]()
                            workflowsTemp[workflowName]?["image"] = workflowImage
                            workflowsTemp[workflowName]?["file"] = workflowFile
                            workflowsTemp[workflowName]?["interpreterName"] = workflowInterpreterName
                        } else {
                            let workflowFileLoaded = (workflowsTemp[workflowName]?["file"])!
                            os_log("Workflow name '%@' already used in '%@'. Workflow file '%@' not loaded.",
                                   log: logGeneral, type: .error, workflowName, workflowFileLoaded, workflowFile)
                            
                            let userInfo:[String: String] = ["workflowName": workflowName,
                                                             "workflowLoadedPath": workflowFileLoaded,
                                                             "workflowSkippedPath": workflowFile]
                            
                            NotificationCenter.default.post(name: .workflowIdenticalName, object: nil,
                                                            userInfo: userInfo)
                        }
                    }
                } catch let error {
                    os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
                }
            }
        }
        
        if workflowsChanged(workflowsNew: workflowsTemp, workflowsOld: AppState.allWorkflows) {
            AppState.allWorkflows = workflowsTemp
            NotificationCenter.default.post(name: .workflowsChanged, object: nil)
        }
    }
    
    func workflowsChanged(workflowsNew: [String: Dictionary<String, String>],
                          workflowsOld: [String: Dictionary<String, String>]) -> Bool {
        
        // Check for added and edited workflows (the-one-way).
        for (name, _):(String, Dictionary<String, String>) in workflowsNew {
            if workflowsOld[name] != nil {
                //log.debug("Workflow '\(name)' was present before.")
                if workflowsOld[name]?["file"] != workflowsNew[name]?["file"] {
                    //log.debug("Workflow '\(name)' file has changed, changes detected, reloading.")
                    return true
                }
                if workflowsOld[name]?["image"] != workflowsNew[name]?["image"] {
                    //log.debug("Workflow '\(name)' image has changed, changes detected, reloading.")
                    return true
                }
                if workflowsOld[name]?["interpreterName"] != workflowsNew[name]?["interpreterName"] {
                    //log.debug("Workflow '\(name)' interpreterName has changed, changes detected, reloading.")
                    return true
                }
            } else {
                //log.debug("Workflow '\(name) was NOT present before, changes detected, reloading.")
                return true
            }
        }
        
        // Check for removed workflows (the-other-way).
        for (name, _):(String, Dictionary<String, String>) in workflowsOld {
            if workflowsNew[name] == nil {
                //log.debug("Workflow '\(name)' was removed, changes detected, reloading.")
                return true
            }
        }
        
        // No changes detected in all checks.
        return false
    }
}
