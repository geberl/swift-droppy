//
//  ViewControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class ViewControllerMain: NSViewController {
    
    @IBOutlet weak var logoImage: NSImageCell!
    @IBOutlet weak var zoneImage: NSImageCell!

    override func viewWillAppear() {
        super.viewWillAppear()
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLine(notification:)),
                                               name: Notification.Name("draggingEnteredOk"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed(notification:)),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed(notification:)),
                                               name: Notification.Name("draggingEnded"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("draggingEnded"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("workflowSelectionChanged"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError(notification:)),
                                               name: Notification.Name("draggingEnteredNoWorkflowSelected"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError(notification:)),
                                               name: Notification.Name("draggingUpdatedNoWorkflowSelected"),
                                               object: nil)
    }
    
    func setZoneDashed(notification: Notification) {
        log.debug("Changing zone image to dashed.")
        zoneImage.image = NSImage(named: "ZoneDashed")
    }
    
    func setZoneLine(notification: Notification) {
        log.debug("Changing zone image to line.")
        zoneImage.image = NSImage(named: "ZoneLine")
    }
    
    func setLogo(notification: Notification) {
        if Workflows.activeLogoFilePath == "" {
            log.debug("Changing workflow logo to default.")
            logoImage.image = NSImage(named: "Logo")
        } else {
            if let newLogo = NSImage(contentsOfFile: Workflows.activeLogoFilePath) {
                log.debug("Workflow logo loaded successfully.")
                let resizedLogo = self.resizeNSImage(image: newLogo, width:128, height:128)
                logoImage.image = resizedLogo
            } else {
                log.error("Can't load workflow logo! Changing to default.")
                logoImage.image = NSImage(named: "Logo")
            }
        }
    }
    
    func setZoneLogoError(notification: Notification) {
        if Workflows.activeLogoFilePath == "" {
            log.debug("Changing workflow logo to error.")
            logoImage.image = NSImage(named: "LogoError")
            
            log.debug("Changing zone image to error.")
            zoneImage.image = NSImage(named: "ZoneError")
        }
    }
    
    func resizeNSImage(image: NSImage, width: Int, height: Int) -> NSImage {
        let destSize = NSMakeSize(CGFloat(width), CGFloat(height))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height),
                   from: NSMakeRect(0, 0, image.size.width, image.size.height),
                   operation: NSCompositingOperation.sourceOver, fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
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