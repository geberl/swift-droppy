//
//  ViewControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerMain: NSViewController {

    let userDefaults = UserDefaults.standard

    var logFilePath: String?

    @IBOutlet weak var logoImageView: NSImageView!

    @IBOutlet weak var zoneImageView: NSImageView!

    @IBOutlet weak var logoImage: NSImageCell!

    @IBOutlet weak var zoneImage: NSImageCell!

    @IBOutlet weak var taskTextField: NSTextField!

    @IBOutlet weak var logButton: NSButton!

    @IBAction func onLogButton(_ sender: NSButton) {
        if let logFilePath = self.logFilePath {
            NSWorkspace.shared().openFile(logFilePath)
        }
    }
    
    @IBOutlet weak var cancelButton: NSButton!
    
    @IBAction func onCancelButton(_ sender: NSButton) {
        os_log("User clicked cancel button during execution.", log: logUi, type: .debug)
        
        self.cancelButton.isEnabled = false
        
        let statusDict: [String: String] = ["text": "Stopping\nPlease wait a moment"]
        NotificationCenter.default.post(name: Notification.Name("executionStatus"), object: nil, userInfo: statusDict)

        NotificationCenter.default.post(name: Notification.Name("executionCancel"), object: nil, userInfo: statusDict)
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLine(notification:)),
                                               name: Notification.Name("draggingEnteredOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError(notification:)),
                                               name: Notification.Name("draggingEnteredNoWorkflowSelected"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError(notification:)),
                                               name: Notification.Name("draggingUpdatedNoWorkflowSelected"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed(notification:)),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("workflowSelectionChanged"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonInvisible(notification:)),
                                               name: Notification.Name("workflowSelectionChanged"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogoSpinner(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonInvisible(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setCancelButtonVisible(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setTextFieldHidden(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonVisible(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setCancelButtonInvisible(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setTextFieldStatus(notification:)),
                                               name: Notification.Name("executionStatus"),
                                               object: nil)
    }
    
    func setTextFieldHidden(notification: Notification) {
        taskTextField.isHidden = true
        taskTextField.stringValue = "Task ?/?"
    }
    
    func setLogButtonInvisible(notification: Notification) {
        self.logFilePath = nil
        self.logButton.isHidden = true
    }
    
    func setLogButtonVisible(notification: Notification) {
        guard let logFilePath = notification.userInfo?["logFilePath"] as? String else { return }
        if logFilePath != "" {
            self.logFilePath = logFilePath
            self.logButton.isHidden = false
        }
    }
    
    func setCancelButtonInvisible(notification: Notification) {
        self.cancelButton.isHidden = true
    }
    
    func setCancelButtonVisible(notification: Notification) {
        self.cancelButton.isEnabled = true
        self.cancelButton.isHidden = false
    }
    
    func setTextFieldStatus(notification: Notification) {
        // Async execution is needed so the first file actually shows up when it is being processed and not when the second one is.
        DispatchQueue.main.async {
            guard let text = notification.userInfo?["text"] as? String else { return }
            self.taskTextField.isHidden = false
            self.taskTextField.stringValue = text
        }
    }
    
    func setZoneDashed(notification: Notification) {
        zoneImage.image = NSImage(named: "zone-dashed")
    }
    
    func setZoneLine(notification: Notification) {
        zoneImage.image = NSImage(named: "zone-line")
    }
    
    func setLogo(notification: Notification) {
        logoImageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        logoImageView.animates = false
        
        guard let workspacePath = checkWorkspaceInfo() else {
            logoImage.image = self.resizeNSImage(image: NSImage(named: "logo-default")!, width: 128, height: 128)
            return
        }
        
        if let logoFile: String = AppState.activeLogoFile {
            let logoPath: String = workspacePath + "Images" + "/" + logoFile
            if let newLogo = NSImage(contentsOfFile: logoPath) {
                logoImage.image = self.resizeNSImage(image: newLogo, width:128, height:128)
            } else {
                os_log("Can't load workflow logo from '%@'.", log: logUi, type: .error, logoPath)
                logoImage.image = self.resizeNSImage(image: NSImage(named: "logo-default")!, width: 128, height: 128)
            }
        } else {
            logoImage.image = self.resizeNSImage(image: NSImage(named: "logo-default")!, width: 128, height: 128)
        }
    }
    
    func setLogoSpinner(notification: Notification) {
        if let asset = NSDataAsset(name: "logo-spinner", bundle: Bundle.main) {
            logoImageView.imageScaling = NSImageScaling.scaleNone
            logoImageView.animates = true
            logoImage.image = NSImage(data: asset.data)
        }
    }
    
    func setZoneLogoError(notification: Notification) {
        logoImage.image = self.resizeNSImage(image: NSImage(named: "error")!,
                                             width: 128, height: 128)
        zoneImage.image = NSImage(named: "zone-error")
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
}
