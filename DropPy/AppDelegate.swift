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
    static var interpretersDefault: Dictionary = ["macOS pre-installed": ["executable": "/usr/bin/python",
                                                                          "arguments": "-B"]]
}


// Workflows object
struct Workflows {
    static var workflows = [String: Dictionary<String, Any>]()
    
    static var activeName = "" as String
    static var activeInterpreterName = "" as String
    static var activeJsonFile = "" as String
    static var activeLogoFilePath = "" as String
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let userDefaults = UserDefaults.standard
    
    var executionInProgress: Bool = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        log.enabled = true
        self.loadUserDefaults()
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // Reload workflows from Workflow sub-directory now to account for json files that could have been added/edited/deleted
        let changesDetected: Bool = self.reloadWorkflows()
        if changesDetected {
            Workflows.activeName = ""
            Workflows.activeInterpreterName = ""
            Workflows.activeJsonFile = ""
            Workflows.activeLogoFilePath = ""
            NotificationCenter.default.post(name: Notification.Name("workflowsChanged"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppDelegate.startPythonExecutor(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)
    }

    func startPythonExecutor(notification: Notification) {
        // Notification is sometimes sent (or received ?) twice.
        // This workaround prevents multiple instantiation and execution of PythonExecutor.
        if !executionInProgress {
            executionInProgress = true

            DispatchQueue.global(qos: .background).async {
                if let filePaths = notification.userInfo?["filePaths"] as? [String] {
                    let pythonExecutor = PythonExecutor(workflowFile: Workflows.activeJsonFile,
                                                        filePaths: filePaths)
                    pythonExecutor.run()
                }
                DispatchQueue.main.async {
                    self.endPythonExecutor()
                }
            }
        }
    }

    func endPythonExecutor() {
        executionInProgress = false
        NotificationCenter.default.post(name: Notification.Name("executionFinished"), object: nil)
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
    
    
    lazy var firstRunWindowController: WindowControllerFirstRun  = {
        let wcSB = NSStoryboard(name: "FirstRun", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerFirstRun
    }()

    @IBAction func showFirstRunWindow(_ sender: Any) {
        self.firstRunWindowController.showWindow(self)
    }

    func loadUserDefaults() {
        // TODO: Create a button to reset everthing (but registration info and demo start datetime) to defaults in advanced tab of preferences instead (closes the app also)
        // self.clearUserDefaults()
        
        // User's DropPy Workspace directory
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.workspacePath) == false{
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
        
        // Dev mode.
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.devModeEnabled) == false {
            userDefaults.set(UserDefaultStruct.devModeEnabledDefault, forKey: UserDefaultStruct.devModeEnabled)
        }
        
        // User's external text editor.
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorAppPath) == false {
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
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorIconPath) == false {
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
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForWorkflows) == false {
            userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
        }
        
        // User's preference for how to edit Tasks.
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForTasks) == false {
            userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }
        
        // User's Python interpreters and virtual envs.
        if self.isKeyPresentInUserDefaults(key: UserDefaultStruct.interpreters) == false {
            userDefaults.set(UserDefaultStruct.interpretersDefault, forKey: UserDefaultStruct.interpreters)
        }
        userDefaults.set(UserDefaultStruct.interpreterStockNameDefault, forKey: UserDefaultStruct.interpreterStockName)
        
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
    
    func reloadWorkflows() -> Bool {
        let workflowDir = "\(userDefaults.string(forKey: UserDefaultStruct.workspacePath) ?? "no default")/Workflows"
        //log.debug("Reloading Workflows from '\(workflowDir)'.")

        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: workflowDir)!

        var workflowsTemp = [String: Dictionary<String, Any>]()
        
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix("json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: "\(workflowDir)/\(element)"), options: .alwaysMapped)
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
        
        if workflowsChanged(workflowsNew: workflowsTemp, workflowsOld: Workflows.workflows) {
            Workflows.workflows = workflowsTemp
            return true
        } else {
            return false
        }
    }
    
    func workflowsChanged(workflowsNew: [String: Dictionary<String, Any>],
                          workflowsOld: [String: Dictionary<String, Any>]) -> Bool {
        
        // Check for added and edited workflows (the-one-way)
        for (name, _):(String, Dictionary<String, Any>) in workflowsNew {
            if workflowsOld[name] != nil {
                //log.debug("Workflow '\(name)' was present before.")
                
                if workflowsOld[name]?["file"] as! String != workflowsNew[name]?["file"] as! String {
                    //log.debug("Workflow '\(name)' file has changed, changes detected, reloading.")
                    return true
                } else {
                    //log.debug("Workflow '\(name)' file is identical.")
                }
                
                if workflowsOld[name]?["image"] as! String != workflowsNew[name]?["image"] as! String {
                    //log.debug("Workflow '\(name)' image has changed, changes detected, reloading.")
                    return true
                } else {
                //log.debug("Workflow '\(name)' image is identical.")
                }
                
                if workflowsOld[name]?["interpreterName"] as! String != workflowsNew[name]?["interpreterName"] as! String {
                    //log.debug("Workflow '\(name)' interpreterName has changed, changes detected, reloading.")
                    return true
                } else {
                    //log.debug("Workflow '\(name)' interpreterName is identical.")
                }

            } else {
                //log.debug("Workflow '\(name) was NOT present before, changes detected, reloading.")
                return true
            }
        }
        
        // Check for removed workflows (the-other-way)
        for (name, _):(String, Dictionary<String, Any>) in workflowsOld {
            if workflowsNew[name] != nil {
                //log.debug("Workflow '\(name)' is still present.")
            } else {
                //log.debug("Workflow '\(name)' was removed, changes detected, reloading.")
                return true
            }
        }
        
        // No changes detected in all checks
        return false
    }
}
