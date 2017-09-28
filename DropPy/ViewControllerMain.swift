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
                                               selector: #selector(ViewControllerMain.setZoneLine),
                                               name: Notification.Name("draggingEnteredOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError),
                                               name: Notification.Name("draggingEnteredNoWorkflowSelected"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneLogoError),
                                               name: Notification.Name("draggingUpdatedNoWorkflowSelected"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo),
                                               name: Notification.Name("draggingExited"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo),
                                               name: Notification.Name("workflowSelectionChanged"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonInvisible),
                                               name: Notification.Name("workflowSelectionChanged"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogoSpinner),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonInvisible),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setCancelButtonVisible),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setZoneDashed),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogo),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setTextFieldHidden),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setLogButtonVisible),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setCancelButtonInvisible),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerMain.setTextFieldStatus),
                                               name: Notification.Name("executionStatus"),
                                               object: nil)
    }
    
    @objc func setTextFieldHidden(_ notification: Notification) {
        taskTextField.isHidden = true
        taskTextField.stringValue = "Task ?/?"
    }
    
    @objc func setLogButtonInvisible(_ notification: Notification) {
        self.logFilePath = nil
        self.logButton.isHidden = true
    }
    
    @objc func setLogButtonVisible(_ notification: Notification) {
        guard let logFilePath = notification.userInfo?["logFilePath"] as? String else { return }
        if logFilePath != "" {
            self.logFilePath = logFilePath
            self.logButton.isHidden = false
        }
    }
    
    @objc func setCancelButtonInvisible(_ notification: Notification) {
        self.cancelButton.isHidden = true
    }
    
    @objc func setCancelButtonVisible(_ notification: Notification) {
        self.cancelButton.isEnabled = true
        self.cancelButton.isHidden = false
    }
    
    @objc func setTextFieldStatus(_ notification: Notification) {
        // Async execution is needed so the first file actually shows up when it is being processed and not when the second one is.
        DispatchQueue.main.async {
            guard let text = notification.userInfo?["text"] as? String else { return }
            self.taskTextField.isHidden = false
            self.taskTextField.stringValue = text
        }
    }
    
    @objc func setZoneDashed(_ notification: Notification) {
        zoneImage.image = NSImage(named: "zone-dashed")
    }
    
    @objc func setZoneLine(_ notification: Notification) {
        zoneImage.image = NSImage(named: "zone-line")
    }
    
    @objc func setLogo(_ notification: Notification) {
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
    
    @objc func setLogoSpinner(_ notification: Notification) {
        if let asset = NSDataAsset(name: "logo-spinner", bundle: Bundle.main) {
            logoImageView.imageScaling = NSImageScaling.scaleNone
            logoImageView.animates = true
            logoImage.image = NSImage(data: asset.data)
        }
    }
    
    @objc func setZoneLogoError(_ notification: Notification) {
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
