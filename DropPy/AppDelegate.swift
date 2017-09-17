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


// Logger configuration
let modifiers: [LogLevel: [LogMessageModifier]] = [.all: [TimestampModifier()]]
let configuration = LoggerConfiguration(modifiers: modifiers)
let log = Logger(configuration: configuration)


struct UserDefaultStruct {
    // This struct ALWAYS needs to contain TWO static variables for each plist record.
    // One to set the KEY's name and one to set the default VALUE and its type.

    static var workspacePath: String = "workspacePath"
    static var workspacePathDefault: String = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("DropPy").path
    
    static var workflowSelected: String = "workflowSelected"
    static var workflowSelectedDefault: String? = nil

    static var devModeEnabled: String = "devModeEnabled"
    static var devModeEnabledDefault: Bool = false

    static var dropCounter: String = "dropCounter"
    static var dropCounterDefault: Int = 0

    static var editorAppPath: String = "editorAppPath"
    static var editorAppPathDefault: String = ""
    static var editorIconPath: String = "editorIconPath"
    static var editorIconPathDefault: String = ""
    static var editorForWorkflows: String = "editorForWorkflows"
    static var editorForWorkflowsDefault: String = "Internal text editor" // TODO: Set "Internal Workflow editor" as default once done.
    static var editorForTasks: String = "editorForTasks"
    static var editorForTasksDefault: String = "Internal text editor"

    static var interpreterStockName: String = "interpreterStockName"
    static var interpreterStockNameDefault: String = "macOS pre-installed"

    static var interpreters: String = "interpreters"
    static var interpretersDefault: Dictionary = ["macOS pre-installed": ["executable": "/usr/bin/python", "arguments": "-B"]]

    static var updateLast: String = "updateLast"
    static var updateLastDefault: Date = Date()
    static var updateDelta: String = "updateDelta"
    static var updateDeltaDefault: Int = 60 * 60 * 24 * 7  // a week in seconds, maxint of UInt64 is much higher.
}


// Workflows object
struct Workflows {
    static var all = [String: Dictionary<String, String>]()

    static var activeName: String?
    static var activeInterpreterName: String?
    static var activeJsonFile: String?
    static var activeLogoFile: String?
}


enum InterpreterError: Error {
    case notFoundInPreferences
    case notSetInWorkflow
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let userDefaults = UserDefaults.standard

    var executionInProgress: Bool = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        log.enabled = true
        self.loadUserDefaults()
        self.autoUpdate()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.reloadWorkflows(notification:)),
                                               name: Notification.Name("reloadWorkflows"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.startPythonExecutor(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        self.reloadWorkflows()
    }

    func reloadWorkflows(notification: Notification) {
        self.reloadWorkflows()
    }

    func checkInterpreterInfo() -> (String?, String?) {
        // TODO also check if executablePath isfile
        let userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        if let activeInterpreterName: String = Workflows.activeInterpreterName {
            if let interpreterInfo: Dictionary<String, String> = userDefaultInterpreters[activeInterpreterName] {
                let executablePath = interpreterInfo["executable"]!
                let executableArgs = interpreterInfo["arguments"]!
                return (executablePath, executableArgs)

            }
        }
        return (nil, nil)
    }

    func startPythonExecutor(notification: Notification) {
        guard let workflowFile: String = Workflows.activeJsonFile else { return }
        let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/"
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)

        // TODO better checks for the three things above, errors to log, error messages to user
        
        let (executablePath, executableArgs) = self.checkInterpreterInfo()
        if (executablePath == nil) || (executableArgs == nil) {
            // TODO better error to log, error messages to user
            log.debug("some error with the executabe, exiting execution")
            return
        }

        // Notification is sometimes sent (or received ?) twice.
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

    func endPythonExecutor(logFilePath: String, tempDirPath: String,
                           exitCode: String) {
        executionInProgress = false

        let pathDict:[String: String] = ["logFilePath": logFilePath,
                                         "tempDirPath": tempDirPath,
                                         "exitCode": exitCode]
        NotificationCenter.default.post(name: Notification.Name("executionFinished"),
                                        object: nil,
                                        userInfo: pathDict)
    }

    func applicationWillTerminate(_ notification: Notification) {
        self.savePosition()
        log.enabled = false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Actually quit the application when the user closes the window.
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
        self.manualUpdate(silent: false)
    }

    lazy var firstRunWindowController: WindowControllerFirstRun  = {
        let wcSB = NSStoryboard(name: "FirstRun", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerFirstRun
    }()

    @IBAction func showFirstRunWindow(_ sender: Any) {
        self.firstRunWindowController.showWindow(self)
    }

    func loadUserDefaults() {
        // User's DropPy Workspace directory
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.workspacePath) {
            // Start out with default Settings
            // Don't open the Preferences Window, make it as simple and painless and little confusing as possible
            userDefaults.set(UserDefaultStruct.dropCounterDefault, forKey: UserDefaultStruct.dropCounter)
            
            // TODO mine, until I can change this in Preferences to my Development folder
            // userDefaults.set(UserDefaultStruct.workspacePathDefault, forKey: UserDefaultStruct.workspacePath)
            userDefaults.set("/Users/guenther/Development/droppy-workspace", forKey: UserDefaultStruct.workspacePath)
            
            // First Run Experience
            self.firstRunWindowController.showWindow(self)
        } else {
            // TODO: Check if the currently set Workspace directory actually still exists, if not open preferences and prompt to change
        }

        // Last selected Workflow.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.workflowSelected) {
            userDefaults.set(UserDefaultStruct.workflowSelectedDefault, forKey: UserDefaultStruct.workflowSelected)
        }

        // Dev mode.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.devModeEnabled) {
            userDefaults.set(UserDefaultStruct.devModeEnabledDefault, forKey: UserDefaultStruct.devModeEnabled)
        }

        // User's external text editor.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorAppPath) {
            userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
        } else {
            // The key exists, now check if the specified editor (app) also still exists on the system.
            if !isDir(path: userDefaults.string(forKey: UserDefaultStruct.editorAppPath)!) {
                userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
                userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
                userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
                userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
            }
        }
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorIconPath) {
            userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
        } else {
            // The key exists, now check if the specified editor (icns) also still exists on the system.
            if !isFile(path: userDefaults.string(forKey: UserDefaultStruct.editorIconPath)!) {
                userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
                userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
                userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
                userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
            }
        }

        // User's preference for how to edit Workflows.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForWorkflows) {
            userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
        }

        // User's preference for how to edit Tasks.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForTasks) {
            userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }

        // User's Python interpreters and virtual envs.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.interpreters) {
            userDefaults.set(UserDefaultStruct.interpretersDefault, forKey: UserDefaultStruct.interpreters)
        }
        userDefaults.set(UserDefaultStruct.interpreterStockNameDefault, forKey: UserDefaultStruct.interpreterStockName)

        // User's update preferences.
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.updateLast) {
            userDefaults.set(UserDefaultStruct.updateLastDefault, forKey: UserDefaultStruct.updateLast)
        }
        if !self.isKeyPresentInUserDefaults(key: UserDefaultStruct.updateDelta) {
            userDefaults.set(UserDefaultStruct.updateDeltaDefault, forKey: UserDefaultStruct.updateDelta)
        }

        // Get current screen size
        let resolutionX: Int
        let resolutionY: Int
        (resolutionX, resolutionY) = getResolution()
        let resolutionKeyName: String = String(format: "mainWindowPosAt%dx%d", resolutionX, resolutionY)

        // User's main window position for this screen size
        if self.isKeyPresentInUserDefaults(key: resolutionKeyName) {
            let position: Array = self.userDefaults.array(forKey: resolutionKeyName)!
            self.setPosition(positionX: position[0] as! Int, positionY: position[1] as! Int)
        }
    }

    func savePosition() {
        // Get current screen size
        let resolutionX: Int
        let resolutionY: Int
        (resolutionX, resolutionY) = getResolution()
        let resolutionKeyName: String = String(format: "mainWindowPosAt%dx%d", resolutionX, resolutionY)
        
        // Get current window position
        let positionX: Int
        let positionY: Int
        (positionX, positionY) = self.getPosition()
        
        // Save the window position for this screen size
        userDefaults.set([positionX, positionY], forKey: resolutionKeyName)
    }

    func getPosition() -> (Int, Int) {
        let window = NSApplication.shared().windows.first
        let positionX: Int =  Int(window!.frame.origin.x)
        let positionY: Int = Int(window!.frame.origin.y)
        log.debug("getPosition: X: \(positionX), Y: \(positionY)")
        return (positionX, positionY)
    }
    
    func setPosition(positionX: Int, positionY: Int) {
        let position = NSPoint(x: positionX, y: positionY)
        guard let window = NSApplication.shared().windows.first else { return }
        window.setFrameOrigin(position)
        // log.debug(String(format: "setPosition: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
    }
    
    func getResolution() -> (Int, Int) {
        let scrn: NSScreen = NSScreen.main()!
        let rect: NSRect = scrn.frame
        let height = rect.size.height
        let width = rect.size.width
        // log.debug(String(format: "getResolution: X: %.0f, Y: %.0f", height, width))
        return (Int(height), Int(width))
    }
    
    func clearUserDefaults() {
        if let bundle = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundle)
        }
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        if self.userDefaults.object(forKey: key) == nil {
            return false
        } else {
            return true
        }
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

        if workflowsChanged(workflowsNew: workflowsTemp, workflowsOld: Workflows.all) {
            Workflows.all = workflowsTemp
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

    func autoUpdate() {
        let updateDelta: Int = userDefaults.integer(forKey: UserDefaultStruct.updateDelta)
        let updateLast: Date = userDefaults.object(forKey: UserDefaultStruct.updateLast) as! Date
        let updateNext: Date = updateLast.addingTimeInterval(TimeInterval(updateDelta))
        let dateNow: Date = Date()

        if dateNow > updateNext {
            self.manualUpdate(silent: true)
        } else {
            log.debug("Not checking for updates now, next check " + updateNext.iso8601 + ".")
        }
    }

    func manualUpdate(silent: Bool) {
        if !isConnectedToNetwork() {
            log.debug("No network connection available, skipping update check.")
            if !silent {
                NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
            }
            return
        }

        userDefaults.set(Date(), forKey: UserDefaultStruct.updateLast)

        let jsonURL = URL(string: "https://droppyapp.com/version.json")
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        let task = urlSession.dataTask(with: jsonURL!) {data, response, error in
            guard error == nil else {
                log.error("Checking for updates: Server did not respond.")
                log.error((error?.localizedDescription)!)
                DispatchQueue.main.async {
                    if !silent {
                        NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
                    }
                }
                return
            }

            guard let data = data else {
                log.error("Checking for updates: Response of server is empty.")
                DispatchQueue.main.async {
                    if !silent {
                        NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
                    }
                }
                return
            }

            let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
            let versionMajor = json["versionMajor"] as! Int
            let versionMinor = json["versionMinor"] as! Int
            let versionPatch = json["versionPatch"] as! Int
            let versionDict:[String: String] = ["versionString": String(versionMajor) + "." + String(versionMinor) + "." + String(versionPatch),
                                                "releaseNotesLink": json["releaseNotes"] as! String,
                                                "downloadLink": json["download"] as! String]

            DispatchQueue.main.async {
                if self.isLatestVersion(webVersionMajor: versionMajor,
                                        webVersionMinor: versionMinor,
                                        webVersionPatch: versionPatch) {
                    log.debug("Checking for updates: No update available.")
                    if !silent {
                        NotificationCenter.default.post(name: Notification.Name("updateNotAvailable"),
                                                        object: nil,
                                                        userInfo: versionDict)
                    }
                } else {
                    log.debug("Checking for updates: Update available.")
                    NotificationCenter.default.post(name: Notification.Name("updateAvailable"),
                                                    object: nil,
                                                    userInfo: versionDict)
                }
            }
        }
        task.resume()
    }

    func isLatestVersion(webVersionMajor: Int, webVersionMinor: Int, webVersionPatch: Int) -> Bool {
        if let thisVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            let thisVersionList: [String] = thisVersion.components(separatedBy: ".")
            let thisVersionMajor: Int = Int(thisVersionList[0])!
            let thisVersionMinor: Int = Int(thisVersionList[1])!
            let thisVersionPatch: Int = Int(thisVersionList[2])!

            if webVersionMajor > thisVersionMajor {
                return false
            } else if webVersionMinor > thisVersionMinor {
                return false
            } else if webVersionPatch > thisVersionPatch {
                return false
            }
        } else {
            log.error("Can't get version string from plist.")
        }
        return true
    }
}
