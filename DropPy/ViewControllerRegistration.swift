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
        if let url = URL(string: "https://droppyapp.com/"), NSWorkspace.shared().open(url) {
            log.debug("Main website opened.")
        }
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
        super.viewDidLoad()
        regEvalStatusTextField.stringValue = AppState.regEvalStatus
        
        if AppState.isLicensed {
            self.purchaseButton.isHidden = true
            self.applyButton.title = "Remove license information"

            // TODO fill all those fields with the reg info and make them read only
        }

        if !AppState.isInEvaluation && !AppState.isLicensed {
            // TODO
            log.debug("TODO: slide open a page that friendly tells the user that his evaluation period has ended now")
            
        }
    }
}
