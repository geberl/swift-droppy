//
//  AppDelegate.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import Willow
import SwiftyJSON


// Logger configuration.
let modifiers: [LogLevel: [LogMessageModifier]] = [.all: [TimestampModifier()]]
let configuration = LoggerConfiguration(modifiers: modifiers)
let log = Logger(configuration: configuration)


// Application state object.
struct AppState {
    static var allWorkflows = [String: Dictionary<String, String>]()
    
    static var activeName: String?
    static var activeInterpreterName: String?
    static var activeJsonFile: String?
    static var activeLogoFile: String?
    
    static var interpreterStockName: String = "macOS pre-installed"
    
    static var isLicensed: Bool = false
    static var isInEvaluation: Bool = false
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let userDefaults = UserDefaults.standard

    var executionInProgress: Bool = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        log.enabled = true

        let firstRun: Bool = checkFirstRun()
        validatePrefs()
        autoUpdate()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.reloadWorkflows(notification:)),
                                               name: Notification.Name("reloadWorkflows"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.startPythonExecutor(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        if firstRun {
            self.firstRunWindowController.showWindow(self)
        }
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        self.reloadWorkflows()
        cryptoStuff()
    }

    func reloadWorkflows(notification: Notification) {
        self.reloadWorkflows()
    }

    func checkInterpreterInfo() -> (String?, String?) {
        // TODO also check if executablePath isfile
        let userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        if let activeInterpreterName: String = AppState.activeInterpreterName {
            if let interpreterInfo: Dictionary<String, String> = userDefaultInterpreters[activeInterpreterName] {
                let executablePath = interpreterInfo["executable"]!
                let executableArgs = interpreterInfo["arguments"]!
                return (executablePath, executableArgs)

            }
        }
        return (nil, nil)
    }

    func startPythonExecutor(notification: Notification) {
        guard let workflowFile: String = AppState.activeJsonFile else { return }
        let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/"
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)

        // TODO better checks for the three things above, errors to log, error messages to user
        
        let (executablePath, executableArgs) = self.checkInterpreterInfo()
        if (executablePath == nil) || (executableArgs == nil) {
            // TODO better error to log, error messages to user
            log.debug("some error with the executabe, exiting execution")
            return
        }

        // Notification is sometimes sent (or received?) twice.
        // This workaround prevents multiple instantiation of PythonExecutor.
        if !executionInProgress {
            executionInProgress = true

            var logFilePath: String = ""
            var tempDirPath: String = ""
            var exitCode: String = "0"

            DispatchQueue.global(qos: .background).async {
                if let filePaths = notification.userInfo?["filePaths"] as? [String] {

                    let pythonExecutor = PythonExecutor(filePaths: filePaths,
                                                        workflowFile: workflowFile,
                                                        workspacePath: workspacePath,
                                                        executablePath: executablePath!,
                                                        executableArgs: executableArgs!,
                                                        devModeEnabled: devModeEnabled)
                    pythonExecutor.run()
                    (logFilePath, tempDirPath, exitCode) = pythonExecutor.evaluate()
                }
                DispatchQueue.main.async {
                    self.endPythonExecutor(logFilePath: logFilePath,
                                           tempDirPath: tempDirPath,
                                           exitCode: exitCode)
                }
            }
        }
    }

    func endPythonExecutor(logFilePath: String, tempDirPath: String, exitCode: String) {
        executionInProgress = false

        let pathDict:[String: String] = ["logFilePath": logFilePath,
                                         "tempDirPath": tempDirPath,
                                         "exitCode": exitCode]

        NotificationCenter.default.post(name: Notification.Name("executionFinished"),
                                        object: nil,
                                        userInfo: pathDict)
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveWindowPosition()
        log.enabled = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    lazy var preferencesWindowController: WindowControllerPrefs  = {
        let wcSb = NSStoryboard(name: "Preferences", bundle: Bundle.main)
        return wcSb.instantiateInitialController() as! WindowControllerPrefs
    }()

    @IBAction func showPreferencesWindow(_ sender: NSMenuItem) {
        self.preferencesWindowController.showWindow(self)
    }

    lazy var registrationWindowController: WindowControllerRegistration  = {
        let wcSb = NSStoryboard(name: "Registration", bundle: Bundle.main)
        return wcSb.instantiateInitialController() as! WindowControllerRegistration
    }()

    @IBAction func showRegistrationWindow(_ sender: NSMenuItem) {
        self.registrationWindowController.showWindow(self)
    }

    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        manualUpdate(silent: false)
    }

    lazy var firstRunWindowController: WindowControllerFirstRun  = {
        let wcSB = NSStoryboard(name: "FirstRun", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerFirstRun
    }()

    @IBAction func showFirstRunWindow(_ sender: Any) {
        self.firstRunWindowController.showWindow(self)
    }

    func reloadWorkflows() {
        guard let workspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath) else {
            log.error("Workspace path not set. Unable to reload Workflows.")
            return
        }
        let workflowPath: String = workspacePath + "/" + "Workflows"
        log.debug("Reloading Workflows from '\(workflowPath)'.")

        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: workflowPath)!

        var workflowsTemp = [String: Dictionary<String, String>]()
        
        while let element = enumerator.nextObject() as? String {
            if element.lowercased().hasSuffix(".json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath + "/" + element), options: .alwaysMapped)
                    let jsonObj = JSON(data: data)
                    if jsonObj != JSON.null {
                        workflowsTemp[jsonObj["name"].stringValue] = [String: String]()
                        workflowsTemp[jsonObj["name"].stringValue]?["image"] = jsonObj["image"].stringValue
                        workflowsTemp[jsonObj["name"].stringValue]?["file"] = element
                        workflowsTemp[jsonObj["name"].stringValue]?["interpreterName"] = jsonObj["interpreterName"].stringValue
                    }
                } catch let error {
                    log.error(error.localizedDescription)
                }
            }
        }

        if workflowsChanged(workflowsNew: workflowsTemp, workflowsOld: AppState.allWorkflows) {
            AppState.allWorkflows = workflowsTemp
            NotificationCenter.default.post(name: Notification.Name("workflowsChanged"), object: nil)
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
