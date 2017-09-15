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

    @IBOutlet weak var logoImageView: NSImageView!

    @IBOutlet weak var zoneImageView: NSImageView!

    @IBOutlet weak var logoImage: NSImageCell!

    @IBOutlet weak var zoneImage: NSImageCell!

    @IBOutlet weak var taskTextField: NSTextField!

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
                                               selector: #selector(ViewControllerMain.setLogoSpinner(notification:)),
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
                                               selector: #selector(ViewControllerMain.setTextFieldStatus(notification:)),
                                               name: Notification.Name("executionStatus"),
                                               object: nil)
    }

    func setTextFieldHidden(notification: Notification) {
        taskTextField.isHidden = true
        taskTextField.stringValue = "Task ?/?"
    }

    func setTextFieldStatus(notification: Notification) {
        // Async execution is needed so the first file actually shows up when it is being processed and not when the second one is.
        DispatchQueue.main.async {
            self.taskTextField.isHidden = false
            guard let taskCurrent = notification.userInfo?["taskCurrent"] as? String else { return }
            guard let taskTotal = notification.userInfo?["taskTotal"] as? String else { return }
            guard let taskName = notification.userInfo?["taskName"] as? String else { return }
            self.taskTextField.stringValue = "Task " + taskCurrent + "/" + taskTotal + "\n" + taskName
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

        if Workflows.activeLogoFilePath == "" {
            logoImage.image = self.resizeNSImage(image: NSImage(named: "logo-default")!, width: 128, height: 128)
        } else {
            if let newLogo = NSImage(contentsOfFile: Workflows.activeLogoFilePath) {
                logoImage.image = self.resizeNSImage(image: newLogo, width:128, height:128)
            } else {
                log.error("Can't load workflow logo from '\(Workflows.activeLogoFilePath).")
                logoImage.image = self.resizeNSImage(image: NSImage(named: "logo-default")!, width: 128, height: 128)
            }
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
        if Workflows.activeLogoFilePath == "" {
            logoImage.image = self.resizeNSImage(image: NSImage(named: "error")!,
                                                 width: 128, height: 128)
            zoneImage.image = NSImage(named: "zone-error")
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

}
