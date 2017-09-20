//
//  ViewControllerRegistration.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerRegistration: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var regEvalStatusTextField: NSTextField!

    @IBOutlet weak var purchaseButton: NSButton!
    
    @IBAction func onPurchaseButton(_ sender: NSButton) {
        self.openPurchaseWebsite()
    }
    
    @IBOutlet weak var applyButton: NSButton!
    
    @IBAction func onApplyButton(_ sender: NSButton) {
        if AppState.isLicensed {
            log.debug("TODO: remove license info now")
            // TODO slide open a page to confirm (yes/no buttons)
            // TODO update userDefaults and AppState if confirmed
        } else {
            log.debug("TODO: check license info now")
            // TODO check and slide open a page either reporting an error or thanking the user for his purchase (just with an ok button that closes it again)
            // TODO update userDefaults and AppState if successful
        }
    }
    
    @IBAction func onCloseButton(_ sender: NSButton) {
        NotificationCenter.default.post(name: Notification.Name("closeRegistration"), object: nil)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerRegistration.reopenPurchaseSheet(notification:)),
                                               name: Notification.Name("reopenPurchaseSheet"),
                                               object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        regEvalStatusTextField.stringValue = AppState.regEvalStatus
        
        if AppState.isLicensed {
            self.purchaseButton.isHidden = true
            self.applyButton.title = "Remove license information"
            
            // TODO fill all those fields with the reg info and make them read only
        }
        
        if !AppState.isLicensed && !AppState.isInEvaluation {
            self.openPurchaseSheet()
        }
    }
    
    func reopenPurchaseSheet(notification: Notification?) {
        let parentWindow = self.view.window!
        if parentWindow.sheets.count == 0 {
            self.openPurchaseSheet()
        }
    }
    
    func openPurchaseSheet() {
        let purchaseAlert = NSAlert()
        purchaseAlert.showsHelp = false
        purchaseAlert.messageText = "Thank you for trying out DropPy"
        purchaseAlert.informativeText += "I hope you found it useful and consider licensing."
        purchaseAlert.informativeText += "\n\nClick the 'Purchase' button to find out about pricing in your country."
        purchaseAlert.addButton(withTitle: "Purchase")
        purchaseAlert.addButton(withTitle: "Cancel")
        purchaseAlert.layout()
        purchaseAlert.icon = NSImage(named: "AppIcon")

        purchaseAlert.beginSheetModal(for: self.view.window!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSAlertFirstButtonReturn {
                self.openPurchaseWebsite()
            }
        })
    }
    
    func openPurchaseWebsite() {
        if let url = URL(string: "https://droppyapp.com/"), NSWorkspace.shared().open(url) {
            log.debug("Main website opened.")
        }
    }
}
