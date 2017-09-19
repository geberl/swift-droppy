//
//  WindowControllerRegistration.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerRegistration: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerRegistration.closeWindow(notification:)),
                                               name: Notification.Name("closeRegistration"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerRegistration.openPurchaseSheet(notification:)),
                                               name: Notification.Name("openPurchaseSheet"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerRegistration.openPurchaseWebsite(notification:)),
                                               name: Notification.Name("openPurchaseWebsite"),
                                               object: nil)
    }
    
    func closeWindow(notification: Notification) {
        self.close()
    }
    
    func openPurchaseSheet(notification: Notification) {
        let purchaseAlert = NSAlert()
        purchaseAlert.showsHelp = false
        purchaseAlert.messageText = "Thank you for trying out DropPy"
        purchaseAlert.informativeText += "I hope you found it useful and consider licensing."
        purchaseAlert.informativeText += "\n\nPlease click the 'Purchase' button to find out about pricing in your country."
        purchaseAlert.addButton(withTitle: "Purchase")
        purchaseAlert.addButton(withTitle: "Cancel")
        purchaseAlert.layout()
        purchaseAlert.icon = NSImage(named: "AppIcon")
        
        purchaseAlert.beginSheetModal(for: NSApplication.shared().mainWindow!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSAlertFirstButtonReturn {
                NotificationCenter.default.post(name: Notification.Name("openPurchaseWebsite"), object: nil)
            }
        })
    }
    
    func openPurchaseWebsite(notification: Notification) {
        if let url = URL(string: "https://droppyapp.com/"), NSWorkspace.shared().open(url) {
            log.debug("Main website opened.")
        }
    }
}
