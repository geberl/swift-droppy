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
        os_log("User clicked 'log' button.", log: logUi, type: .info)
        if let logFilePath = self.logFilePath {
            NSWorkspace.shared.openFile(logFilePath)
        }
    }
    
    @IBOutlet weak var cancelButton: NSButton!
    
    @IBAction func onCancelButton(_ sender: NSButton) {
        os_log("User clicked cancel button during execution.", log: logUi, type: .info)
        
        self.cancelButton.isEnabled = false
        
        let statusDict: [String: String] = ["text": "Stopping\nPlease wait a moment"]
        NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
        
        NotificationCenter.default.post(name: .executionCancel, object: nil)
    }
    
    @IBOutlet weak var devButton: NSButton!
    
    @IBAction func onDevButton(_ sender: NSButton) {
        os_log("User clicked 'dev' button.", log: logUi, type: .info)
        if AppState.tempDirPath == nil {
            AppState.tempDirPath = NSTemporaryDirectory() + "se.eberl.droppy" + "/"
            makeDirs(path: AppState.tempDirPath!)
        }
        NSWorkspace.shared.selectFile(AppState.tempDirPath!, inFileViewerRootedAtPath: AppState.tempDirPath!)
    }
    
    @IBOutlet weak var redropButton: NSButton!
    
    @IBAction func onRedropButton(_ sender: NSButton) {
        os_log("User clicked 're-drop' button.", log: logUi, type: .info)
        NotificationCenter.default.post(name: .droppingStarted, object: nil)
        NotificationCenter.default.post(name: .droppingConcluded, object: nil)
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setZoneLine),
                                               name: .draggingEnteredOk, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setZoneLogoError),
                                               name: .draggingEnteredError, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setZoneDashed),
                                               name: .draggingExited, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogo),
                                               name: .draggingExited, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogo),
                                               name: .workflowSelectionChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogButtonInvisible),
                                               name: .workflowSelectionChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogButtonInvisible),
                                               name: .devModeChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setRedropButtonInvisible),
                                               name: .workflowSelectionChanged, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setRedropButtonInvisible),
                                               name: .devModeChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogoSpinner),
                                               name: .droppingStarted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogButtonInvisible),
                                               name: .droppingStarted, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setCancelButtonVisible),
                                               name: .droppingStarted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setZoneDashed),
                                               name: .executionFinished, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogo),
                                               name: .executionFinished, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setTextFieldHidden),
                                               name: .executionFinished, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setLogButtonVisible),
                                               name: .executionFinished, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setRedropButtonVisible),
                                               name: .executionFinished, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setCancelButtonInvisible),
                                               name: .executionFinished, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setTextFieldStatus),
                                               name: .executionStatus, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerMain.setDevModeOverlay),
                                               name: .devModeChanged, object: nil)
        
        self.setDevModeOverlay(nil)
    }
    
    @objc func setDevModeOverlay(_ notification: Notification?) {
        if userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) {
            self.devButton.isHidden = false
        } else {
            self.devButton.isHidden = true
        }
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
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        if devModeEnabled {
            guard let timestampDirPath = notification.userInfo?["timestampDirPath"] as? String else { return }
            if timestampDirPath != "" {
                self.logFilePath = timestampDirPath + "droppy.log"
                self.logButton.isHidden = false
            }
        }
    }
    
    @objc func setRedropButtonInvisible(_ notification: Notification) {
        self.redropButton.isHidden = true
    }
    
    @objc func setRedropButtonVisible(_ notification: Notification) {
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        if devModeEnabled {
            self.redropButton.isHidden = false
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
        // Determine if there should not be the line version set instead.
        if let executionInProgress = notification.userInfo?["executionInProgress"] as? Bool {
            if executionInProgress {
                self.setZoneLine(nil)
                return
            }
        }
        
        // Execution is not in progress, set the dashed version.
        zoneImage.image = NSImage(named: "zone-dashed")
    }
    
    @objc func setZoneLine(_ notification: Notification?) {
        zoneImage.image = NSImage(named: "zone-line")
    }
    
    @objc func setLogo(_ notification: Notification) {
        // Determine if there should not be the spinner logo set instead.
        if let executionInProgress = notification.userInfo?["executionInProgress"] as? Bool {
            if executionInProgress {
                self.setLogoSpinner(nil)
                return
            }
        }
        
        // Execution is not in progress, set the Workflow's image, or the default one.
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
    
    @objc func setLogoSpinner(_ notification: Notification?) {
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
