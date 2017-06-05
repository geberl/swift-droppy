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


// Settings object
struct Settings {
    static var baseFolder = "Dropbox/DropPy/" as String
    static var file = "settings.json" as String
    static var frameworks = [String: Dictionary<String, String>]()
    
    struct Window {
        static var configName = "Default" as String
        static var resolutionX = "not set" as String
        static var resolutionY = "not set" as String
        static var positionX = "not set" as String
        static var positionY = "not set" as String
    }
}

// Workflows object
struct Workflows {
    static var workflows = [String: Dictionary<String, String>]()
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        log.enabled = true
        self.loadSettings()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.getPosition()
        self.saveSettings()
        log.enabled = false
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // Reload workflows from workflow dir now to account for added/edited/deleted json files
        var changesDetected: Bool
        changesDetected = self.reloadWorkflows()
        if changesDetected {
            NotificationCenter.default.post(name: Notification.Name("workflowChanges"), object: nil)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func getPosition() {
        guard let window = NSApplication.shared().windows.first else { return }
        Settings.Window.positionX = String(format: "%.0f", window.frame.origin.x)
        Settings.Window.positionY = String(format: "%.0f", window.frame.origin.y)
        
        log.debug(String(format: "Get Position: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
    }
    
    func printSettings() {
        log.debug("Settings --------------")
        log.debug("Base Folder: \(Settings.baseFolder)")
        log.debug("File: \(Settings.file)")
        log.debug("Window")
        log.debug("  Config Name: \(Settings.Window.configName)")
        log.debug("  Res X: \(Settings.Window.resolutionX), Res Y: \(Settings.Window.positionY)")
        log.debug("  Pos X: \(Settings.Window.positionX), Pos Y: \(Settings.Window.positionY)")
        log.debug("Frameworks: \(Settings.frameworks)")
        log.debug("-----------------------")
    }

    func setPosition() {
        let numberFormatter = NumberFormatter()
        let position = NSPoint(x: numberFormatter.number(from: Settings.Window.positionX)!.intValue,
                               y: numberFormatter.number(from: Settings.Window.positionY)!.intValue)
        
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
                    // TODO load the correct Window settings to begin with, call getScreenResolution and pick out the one that has the same resolution x/y
                    //getResolution()
                    
                    // Just use the first configName for now, discard all others
                    let allWindowConfigs = jsonObj["window"].dictionaryValue as Dictionary
                    for (name, _):(String, JSON) in allWindowConfigs {
                        Settings.Window.configName = name
                        break
                    }
                    Settings.Window.configName = "Dell external screen"
                    Settings.Window.resolutionX = jsonObj["window"][Settings.Window.configName]["resolution x"].stringValue
                    Settings.Window.resolutionY = jsonObj["window"][Settings.Window.configName]["resolution y"].stringValue
                    Settings.Window.positionX = jsonObj["window"][Settings.Window.configName]["position x"].stringValue
                    Settings.Window.positionY = jsonObj["window"][Settings.Window.configName]["position y"].stringValue
                    
                    let allFrameworks = jsonObj["frameworks"].dictionaryValue as Dictionary
                    for (name, paramsJson):(String, JSON) in allFrameworks {
                        Settings.frameworks[name] = [String: String]()
                        let params = paramsJson.dictionaryValue as Dictionary
                        for (param, value):(String, JSON) in params {
                            Settings.frameworks[name]?[param] = value.stringValue
                        }
                    }
                    
                    //printSettings()
                    setPosition()
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
    
    func getResolution() {
        let scrn: NSScreen = NSScreen.main()!
        let rect: NSRect = scrn.frame
        let height = rect.size.height
        let width = rect.size.width
        log.debug(String(format: "Resolution: X: %.0f, Y: %.0f", height, width))
    }
    
    func saveSettings() {
        log.debug("Saving settings")
        
        // Create SwiftyJSON object from the values that should be saved
        let jsonObject: JSON = ["window": [Settings.Window.configName: ["resolution x": Settings.Window.resolutionX,
                                                                        "resolution y": Settings.Window.resolutionY,
                                                                        "position x": Settings.Window.positionX,
                                                                        "position y": Settings.Window.positionY]],
                                "frameworks": Settings.frameworks
        ]
        
        // Convert SwiftyJSON object to string
        let jsonString = jsonObject.description
        //log.debug("jsonString: '\(jsonString)'")
        
        // Setup objects needed for directory and file access
        let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
        let filePath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)\(Settings.file)")
        
        // Write json string to file, this overwrites a preexisting file here
        do {
            try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
    
    func reloadWorkflows() -> Bool {
        let workflowDir = "/Users/guenther/\(Settings.baseFolder)Workflows"
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
                    log.debug("Workflow '\(name)' file has changed, changes detected, exiting.")
                    return true
                } else {
                    log.debug("Workflow '\(name)' file is identical.")
                }
                if workflowsOld[name]?["image"] != workflowsNew[name]?["image"] {
                    log.debug("Workflow '\(name)' image has changed, changes detected, exiting.")
                    return true
                } else {
                log.debug("Workflow '\(name)' image is identical.")
                }
            } else {
                log.debug("Workflow '\(name) was NOT present before, changes detected, exiting.")
                return true
            }
        }
        
        // Check for removed workflows (the-other-way)
        for (name, _):(String, Dictionary<String, String>) in workflowsOld {
            if workflowsNew[name] != nil {
                log.debug("Workflow '\(name)' is still present.")
            } else {
                log.debug("Workflow '\(name)' was removed, changes detected, exiting.")
                return true
            }
        }
        
        // No changes detected in all checks
        return false
    }
}
