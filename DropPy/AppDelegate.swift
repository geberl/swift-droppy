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


// Settings object (with defaults)
struct Settings {
    static var baseFolder = "DropPy/" as String
    static var file = "settings.json" as String

    static var frameworks = [String: Dictionary<String, String>]()
    static var editor = "TextEdit" as String
    
    static var screenSizes = [String: Dictionary<String, String>]()
    
        //static var configName = "Default" as String
        //static var resolutionX = "not set" as String
        //static var resolutionY = "not set" as String
        //static var positionX = "not set" as String
        //static var positionY = "not set" as String
}

// Workflows object
struct Workflows {
    static var workflows = [String: Dictionary<String, String>]()
    static var activeName = "" as String
    static var activeJsonFile = "" as String
    static var activeLogoFilePath = "" as String
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        log.enabled = true
        self.loadSettings()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Get current window position
        var positionX: Int
        var positionY: Int
        (positionX, positionY) = self.getPosition()
        
        // Get current screen size
        var resolutionX: Int
        var resolutionY: Int
        (resolutionX, resolutionY) = getResolution()
        
        // Save the window position for this screen size to the Settings object
        self.updatePosition(resolutionX: resolutionX, resolutionY: resolutionY, positionX: positionX, positionY: positionY)
        
        // Save all settings to file
        self.saveSettings()
        
        log.enabled = false
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // Reload workflows from workflow dir now to account for json files that could have been added/edited/deleted
        let changesDetected: Bool = self.reloadWorkflows()
        if changesDetected {
            Workflows.activeName = ""
            Workflows.activeJsonFile = ""
            Workflows.activeLogoFilePath = ""
            NotificationCenter.default.post(name: Notification.Name("workflowsChanged"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Actually quit the application when the user closes the window
        return true
    }
    
    func getPosition() -> (Int, Int) {
        let window = NSApplication.shared().windows.first
        let positionX: Int =  Int(window!.frame.origin.x)
        let positionY: Int = Int(window!.frame.origin.y)
        log.debug("Get Position: X: \(positionX), Y: \(positionY)")
        return (positionX, positionY)
    }
    
    func updatePosition(resolutionX: Int, resolutionY: Int, positionX: Int, positionY: Int) {
        Settings.screenSizes["\(resolutionX)x\(resolutionY)"] = ["positionX": String(positionX),
                                                                 "positionY": String(positionY)]
    }

    func setPosition(positionX: Int, positionY: Int) {
        let position = NSPoint(x: positionX, y: positionY)
        guard let window = NSApplication.shared().windows.first else { return }
        window.setFrameOrigin(position)
        
        log.debug(String(format: "Set Position: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
    }
    
    func loadSettings() {
        let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
        let filePath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)\(Settings.file)")
        let strFilePath: String = filePath.path
        let fileManager: FileManager = FileManager.default
        
        if fileManager.fileExists(atPath:strFilePath){
            log.debug("Settings file found at '\(strFilePath)'")
            
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: strFilePath), options: .alwaysMapped)
                let jsonObj = JSON(data: data)
                if jsonObj != JSON.null {

                    // User defined editor
                    if jsonObj["editor"] != JSON.null {
                        Settings.editor = jsonObj["editor"].stringValue
                    }

                    // Window positions for screen sizes
                    if jsonObj["screenSizes"] != JSON.null {
                        Settings.screenSizes = jsonObj["screenSizes"].rawValue as! [String : Dictionary<String, String>]
                        
                        // Get current screen size
                        var resolutionX: Int
                        var resolutionY: Int
                        (resolutionX, resolutionY) = getResolution()

                        // Pick current window configurations for all screen sizes
                        var screenSizeFound: Bool = false
                        for (name, value):(String, Dictionary<String, String>) in Settings.screenSizes {
                            if name == "\(resolutionX)x\(resolutionY)" {
                                log.debug("Screen Size '\(resolutionX)x\(resolutionY)' found, loading window position.")
                                self.setPosition(positionX: Int(value["positionX"]!)!,
                                                 positionY: Int(value["positionY"]!)!)
                                screenSizeFound = true
                                break
                            }
                        }
                        if screenSizeFound == false {
                            log.debug("Screen Size '\(resolutionX)x\(resolutionY)' not found, loading default window position (centered).")
                        }
                    } else {
                        log.debug("Config contains no screen sizes, loading default window position (centered).")
                    }

                    let allFrameworks = jsonObj["frameworks"].dictionaryValue as Dictionary
                    for (name, paramsJson):(String, JSON) in allFrameworks {
                        Settings.frameworks[name] = [String: String]()
                        let params = paramsJson.dictionaryValue as Dictionary
                        for (param, value):(String, JSON) in params {
                            Settings.frameworks[name]?[param] = value.stringValue
                        }
                    }

                } else {
                    log.error("Could not get json from file, make sure that file contains valid json.")
                }
            } catch let error {
                log.error(error.localizedDescription)
            }
        } else {
            log.warn("Settings file NOT found at '\(strFilePath)'")
        }
    }
    
    func getResolution() -> (Int, Int) {
        let scrn: NSScreen = NSScreen.main()!
        let rect: NSRect = scrn.frame
        let height = rect.size.height
        let width = rect.size.width
        log.debug(String(format: "Resolution: X: %.0f, Y: %.0f", height, width))
        return (Int(height), Int(width))
    }
    
    func saveSettings() {
        log.debug("Saving settings")

        // Create SwiftyJSON object from the values that should be saved
        let jsonObject: JSON = ["editor": Settings.editor,
                                "screenSizes": Settings.screenSizes,
                                "frameworks": Settings.frameworks]
  
        // Convert SwiftyJSON object to string
        let jsonString = jsonObject.description

        // Setup objects needed for directory and file access
        let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
        let filePath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)\(Settings.file)")
        
        // Write json string to file, this overwrites a preexisting file at this location
        do {
            try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
    
    func reloadWorkflows() -> Bool {
        let userDir: String = FileManager.default.homeDirectoryForCurrentUser.path
        let workflowDir = "\(userDir)/\(Settings.baseFolder)Workflows"
        log.debug("Reloading Workflows from '\(workflowDir)'")

        let fileManager = FileManager.default
        let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: workflowDir)!
        
        var workflowsTemp = [String: Dictionary<String, String>]()
        
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix("json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: "\(workflowDir)/\(element)"), options: .alwaysMapped)
                    let jsonObj = JSON(data: data)
                    if jsonObj != JSON.null {
                        workflowsTemp[jsonObj["name"].stringValue] = [String: String]()
                        workflowsTemp[jsonObj["name"].stringValue]?["image"] = jsonObj["image"].stringValue
                        workflowsTemp[jsonObj["name"].stringValue]?["file"] = element
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
    
    func workflowsChanged(workflowsNew: [String: Dictionary<String, String>],
                          workflowsOld: [String: Dictionary<String, String>]) -> Bool {
        
        // Check for added and edited workflows (one-way)
        for (name, _):(String, Dictionary<String, String>) in workflowsNew {
            if workflowsOld[name] != nil {
                log.debug("Workflow '\(name)' was present before.")
                if workflowsOld[name]?["file"] != workflowsNew[name]?["file"] {
                    log.debug("Workflow '\(name)' file has changed, changes detected, reloading.")
                    return true
                } else {
                    log.debug("Workflow '\(name)' file is identical.")
                }
                if workflowsOld[name]?["image"] != workflowsNew[name]?["image"] {
                    log.debug("Workflow '\(name)' image has changed, changes detected, reloading.")
                    return true
                } else {
                log.debug("Workflow '\(name)' image is identical.")
                }
            } else {
                log.debug("Workflow '\(name) was NOT present before, changes detected, reloading.")
                return true
            }
        }
        
        // Check for removed workflows (the-other-way)
        for (name, _):(String, Dictionary<String, String>) in workflowsOld {
            if workflowsNew[name] != nil {
                log.debug("Workflow '\(name)' is still present.")
            } else {
                log.debug("Workflow '\(name)' was removed, changes detected, reloading.")
                return true
            }
        }
        
        // No changes detected in all checks
        return false
    }
}
