//
//  ViewController.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import Foundation
import SwiftyJSON


struct Settings {
    static var baseFolder = "Dropbox/DropPy/" as String
    static var file = "settings.json" as String
    static var selectedWorkflow = "not set" as String
    static var frameworks = [String: Dictionary<String, String>]()

    // TODO specify sensible defaults for the following values instead of placeholder strings without meaning
    struct Window {
        static var configName = "Default" as String
        static var resolutionX = "not set" as String
        static var resolutionY = "not set" as String
        static var positionX = "not set" as String
        static var positionY = "not set" as String
    }
}


class ViewController: NSViewController {
    
    @IBOutlet weak var DropDownOutlet: NSPopUpButton!
    @IBOutlet weak var MyImage: NSImageCell!

    @IBAction func SettingsButton(_ sender: Any) {
        log.debug("abc")
        resetImage()
    }

    @IBAction func DropDownAction(_ sender: NSPopUpButton) {
        log.debug("DropDown changed, now #\(sender.indexOfSelectedItem) - \(sender.titleOfSelectedItem!)")
        Settings.selectedWorkflow = sender.titleOfSelectedItem!
        // TODO also change image now
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        loadSettings()
        
        DropDownOutlet.removeAllItems()
        DropDownOutlet.addItem(withTitle: "abc")
        DropDownOutlet.addItem(withTitle: "def")
        DropDownOutlet.addItem(withTitle: "ghi")

        DropDownOutlet.selectItem(withTitle: "ghi")
        Settings.selectedWorkflow = "ghi"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        getPosition()
        saveSettings()
    }
    
    func resetImage() {
        MyImage.image = NSImage(named: "zone")
    }
    
    func getSelectedWorkflow() {
        let workflow = DropDownOutlet.titleOfSelectedItem!  // Does not work when called from runScriptJson because of different instance (or no instance at all, just statically called a function of a class); currently working around this limitation by saving the currently selected Workflow string into the globally available settings object (which is bad but works)
        log.debug("\(workflow)")
    }
    
    func printSettings() {
        log.debug("Settings --------------")
        log.debug("Base Folder: \(Settings.baseFolder)")
        log.debug("File: \(Settings.file)")
        log.debug("Selected Workflow: \(Settings.selectedWorkflow)")
        log.debug("Window")
        log.debug("  Config Name: \(Settings.Window.configName)")
        log.debug("  Res X: \(Settings.Window.resolutionX), Res Y: \(Settings.Window.positionY)")
        log.debug("  Pos X: \(Settings.Window.positionX), Pos Y: \(Settings.Window.positionY)")
        log.debug("Frameworks: \(Settings.frameworks)")
        log.debug("-----------------------")
    }

    func getPosition() {
        guard let window = NSApplication.shared().windows.first else { return }
        Settings.Window.positionX = String(format: "%.0f", window.frame.origin.x)
        Settings.Window.positionY = String(format: "%.0f", window.frame.origin.y)
        
        log.debug(String(format: "Get Position: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
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

                    Settings.selectedWorkflow = jsonObj["selected workflow"].stringValue
                    
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
        let jsonObject: JSON = ["selected workflow": Settings.selectedWorkflow,
                                "window": [Settings.Window.configName: ["resolution x": Settings.Window.resolutionX,
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

    func executeCommand(command: String, args: [String]) -> String {
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output        
    }
    
    func runScriptJson(path: String) {
        // Run python script through interpreter
        // Passing -B to not get a __pycache__folder, the full path to executor.py and the full path to the json file
        // The final output of the command is empty, no point in printing it to the log, the piped messages already are printed
        
        //let commandOutput = executeCommand(command: "/bin/echo", args: ["Hello, I am here!"])
        //let commandOutput = executeCommand(command: "/bin/cp", args: [path, path + ".bak"])
        //log.debug("Command Outout: \(commandOutput)")
        
        let framework = "Python 3"
        log.debug("\(Settings.selectedWorkflow)")

        if Settings.frameworks[framework] != nil {
            log.debug("Framework '\(framework)' found")

            let interpreter: String = Settings.frameworks[framework]!["interpreter"]!
            let interpreterArgs: String = Settings.frameworks[framework]!["interpreter args"]!
            
            let runner: String = Settings.frameworks[framework]!["runner"]!
            let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
            let runnerPath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)\(framework)/\(runner)")
            let strRunnerPath: String = runnerPath.path
            
            var runnerArgs: String = Settings.frameworks[framework]!["runner args"]!
            runnerArgs = runnerArgs.replacingOccurrences(of: "$(JSONFILE)", with: path)
            
            log.debug("  Interpreter: \(interpreter) \(interpreterArgs)")
            log.debug("  Runner: \(strRunnerPath) \(runnerArgs)")

            _ = executeCommand(command: interpreter, args: [interpreterArgs, strRunnerPath, runnerArgs])
        }
        else {
            log.error("Framework '\(framework)' not found in settings.json!")
        }
    }
}
