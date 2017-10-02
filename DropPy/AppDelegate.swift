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
    
    static var activeName: String?
    static var activeInterpreterName: String?
    static var activeJsonFile: String?
    static var activeLogoFile: String?
    
    static var interpreterStockName: String = "macOS pre-installed"
    static var bundledWorkspaceVersion: String = "trunk (5374e25) (2017-09-15)"
    static var bundledRunVersion: String = "trunk (ac8139a) (2017-09-07)"
    
    static var evalStartSalt: String = "nBL4QzmKbk8vhnfke9uvNHRDUtwkoPvJ"
    
    static var isLicensed: Bool = false
    static var isInEvaluation: Bool = false
    static var regEvalStatus: String = "Unlicensed (Evaluation)"
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let userDefaults = UserDefaults.standard

    var executionInProgress: Bool = false
    
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
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.reloadWorkflows),
                                               name: .reloadWorkflows, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.startPythonExecutor),
                                               name: .droppingOk, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewInterpreter),
                                               name: .interpreterNotFound, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewEditor),
                                               name: .editorNotFound, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.setNewWorkspace),
                                               name: .workspaceNotFound, object: nil)
        
        self.devModeMenuItem.isEnabled = true  // override auto enabling in "Workflow" menu for this item.

        if isFirstRun() {
            beginEvaluation()
            reapplyPrefs()
            self.firstRunWindowController.showWindow(self)
        } else {
            reapplyPrefs()
            loadWindowPosition()
            self.loadDevMenuState()
            
            AppState.isLicensed = isLicensed()
            if !AppState.isLicensed {
                os_log("No license information found.", log: logLicense, type: .info)
                AppState.isInEvaluation = isInEvaluation()
            }
            
            if !AppState.isInEvaluation && !AppState.isLicensed {
                self.registrationWindowController.showWindow(self)
            }

            autoUpdate()
        }
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        self.reloadWorkflowsFromDir()
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
        // Show registration window with open pruchase sheet to user on each drop.
        // At this moment do not refuse executing, maybe later in 2.0.
        if !AppState.isInEvaluation && !AppState.isLicensed {
            self.registrationWindowController.showWindow(self)
            NotificationCenter.default.post(name: .reopenPurchaseSheet, object: nil)
        }
        
        guard let workflowFile: String = AppState.activeJsonFile else { return }
        
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        let workspacePath = checkWorkspaceInfo()
        let (executablePath, executableArgs) = self.checkInterpreterInfo()
        if (workspacePath == nil) || (executablePath == nil) || (executableArgs == nil) {
            NotificationCenter.default.post(name: .executionFinished, object: nil)
            return
        }

        // The notification that starts this function is sometimes sent (or received?) twice.
        // Using a boolean class variable as a workaround prevents multiple instantiation of DropHandler/PythonExecutor.
        if !self.executionInProgress {
            self.executionInProgress = true
            
            // Usually doesn't appear on screen, because the steps until the first Task is executed happen so fast.
            let statusDict: [String: String] = ["text": "Preparing"]
            NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
            
            var logFilePath: String = ""
            var tempPath: String = ""
            var dropExitCode: Int = 0
            var execExitCode: Int = 0

            DispatchQueue.global(qos: .background).async {
                if let draggingPasteboard = notification.userInfo?["draggingPasteboard"] as? NSPasteboard {
                    let dropHandler = DropHandler(draggingPasteboard: draggingPasteboard,
                                                  workspacePath: workspacePath!,
                                                  devModeEnabled: devModeEnabled)
                    dropHandler.run()
                    (logFilePath, tempPath, dropExitCode) = dropHandler.evaluate()
                } else {
                    os_log("Unable to access draggingPasteboard. Skipping DropHandler.", log: logDrop, type: .error)
                    dropExitCode = 1
                }
                
                if dropExitCode == 0 {
                    let pythonExecutor = PythonExecutor(workflowFile: workflowFile,
                                                        workspacePath: workspacePath!,
                                                        executablePath: executablePath!,
                                                        executableArgs: executableArgs!,
                                                        devModeEnabled: devModeEnabled,
                                                        tempPath: tempPath,
                                                        logFilePath: logFilePath)
                    pythonExecutor.run()
                    execExitCode = pythonExecutor.evaluate()
                } else {
                    os_log("Skipping Workflow execution. DropHandler reported error.", log: logExecution, type: .error)
                }

                DispatchQueue.main.async {
                    self.endPythonExecutor(logFilePath: logFilePath, tempPath: tempPath,
                                           dropExitCode: dropExitCode, execExitCode: execExitCode)
                }
            }
        }
    }
    
    func endPythonExecutor(logFilePath: String, tempPath: String, dropExitCode: Int, execExitCode: Int) {
        self.executionInProgress = false

        let pathDict:[String: String] = ["logFilePath": logFilePath,
                                         "tempPath": tempPath,
                                         "dropExitCode": String(dropExitCode),
                                         "execExitCode": String(execExitCode)]

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
        
        var informativeText: String = "The Workspace directory can't be found.\n\n"
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
    
    lazy var firstRunWindowController: WindowControllerFirstRun  = {
        let wcSB = NSStoryboard(name: NSStoryboard.Name(rawValue: "FirstRun"), bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerFirstRun
    }()
    
    @IBAction func showFirstRunWindow(_ sender: Any) {
        self.firstRunWindowController.showWindow(self)
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
                        workflowsTemp[jsonObj["name"].stringValue] = [String: String]()
                        workflowsTemp[jsonObj["name"].stringValue]?["image"] = jsonObj["image"].stringValue
                        workflowsTemp[jsonObj["name"].stringValue]?["file"] = element
                        workflowsTemp[jsonObj["name"].stringValue]?["interpreterName"] = jsonObj["interpreterName"].stringValue
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
