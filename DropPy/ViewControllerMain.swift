//
//  ViewControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class ViewControllerMain: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
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
        log.debug("Changing zone image to 'zone-dashed'.")
        zoneImage.image = NSImage(named: "zone-dashed")
    }
    
    func setZoneLine(notification: Notification) {
        log.debug("Changing zone image to 'zone-line'.")
        zoneImage.image = NSImage(named: "zone-line")
    }
    
    func setLogo(notification: Notification) {
        if Workflows.activeLogoFilePath == "" {
            log.debug("Changing workflow logo to 'logo'.")
            logoImage.image = self.resizeNSImage(image: NSImage(named: "logo")!, width: 128, height: 128)
        } else {
            if let newLogo = NSImage(contentsOfFile: Workflows.activeLogoFilePath) {
                log.debug("Workflow logo loaded successfully from '\(Workflows.activeLogoFilePath)'.")
                logoImage.image = self.resizeNSImage(image: newLogo, width:128, height:128)
            } else {
                log.error("Can't load workflow logo from '\(Workflows.activeLogoFilePath).")
                log.debug("Changing workflow logo to 'logo'.")
                logoImage.image = self.resizeNSImage(image: NSImage(named: "logo")!, width: 128, height: 128)
            }
        }
    }
    
    func setZoneLogoError(notification: Notification) {
        if Workflows.activeLogoFilePath == "" {
            log.debug("Changing workflow logo to 'error'.")
            logoImage.image = self.resizeNSImage(image: NSImage(named: "error")!, width: 128, height: 128)
            
            log.debug("Changing zone image to 'zone-error'.")
            zoneImage.image = NSImage(named: "zone-error")
        }
    }
    
    func resizeNSImage(image: NSImage, width: Int, height: Int) -> NSImage {
        log.debug("begin resizing")
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
    
    func runScriptJson(path: String) {
        // TODO the following does not work, because the function is not called on the instance but without an instance!
        // Result: bachball is found (not nil) but logoImage.image is nil and can't be set
        // logoImage.image = self.resizeNSImage(image: NSImage(named: "beachball"), width: 128, height: 128)

        // On default passing -B to not get a __pycache__folder, the full path to run.py and the full path to the json file
        // The final output of the command is empty, no point in printing it to the log, the piped messages already are printed
        
        // Check if the workflow's set interpreter is present in the settings object
        if userDefaults.dictionary(forKey: UserDefaultStruct.interpreters)![Workflows.activeInterpreterName] != nil {

            log.debug("Interpreter '\(Workflows.activeInterpreterName)' found")
            
            let interpreterInfo: Dictionary<String, String> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters)![Workflows.activeInterpreterName] as! Dictionary<String, String>

            // Get the needed arguments from the sessings object
            let executablePath: String = interpreterInfo["executable"]!
            let executableArgs: String = interpreterInfo["arguments"]!
            let runnerName: String = "run.py"
            let runnerDir = "\(userDefaults.string(forKey: UserDefaultStruct.workspacePath) ?? "no default")/Runners"
            let runnerPath: String = "\(runnerDir)/\(runnerName)"
            var runnerArgs: String = "--items=$(JSONFILE)"
            runnerArgs = runnerArgs.replacingOccurrences(of: "$(JSONFILE)", with: path)
            
            log.debug("  Executable: \(executablePath) \(executableArgs)")
            log.debug("  Runner: \(runnerPath) \(runnerArgs)")

            // Call Python executable with arguments
            // TODO also pass temp folder to use here, allow the workflow to use "debug" mode and save all temp files there
            _ = executeCommand(command: executablePath, args: [executableArgs, runnerPath, runnerArgs])
        }
        else {
            log.error("Interpreter '\(Workflows.activeInterpreterName)' not found in userDefaults!")
        }
    }
}
