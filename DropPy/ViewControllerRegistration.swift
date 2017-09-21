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
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var companyTextField: NSTextField!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var licenseCodeTextField: NSTextField!
    @IBOutlet weak var purchaseButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!

    @IBAction func onPurchaseButton(_ sender: NSButton) {
        self.openPurchaseWebsite()
    }
    
    @IBAction func onApplyButton(_ sender: NSButton) {
        if AppState.isLicensed {
            log.debug("Removing license info.")
            self.showRemoveSheet()
        } else {
            log.debug("Checking license info.")
            
            if !self.validateInput() {
                log.error("Input invalid")
                return
            }
            
            let licenseCode = self.licenseCodeTextField.stringValue
            log.debug("Entered license code: " + licenseCode)
            
            let validLicense: Bool = checkValidLicense(licenseCode: licenseCode, regName: self.getRegName())
            if validLicense {
                log.info("Result: License code is valid.")
                self.saveRegValues()
                self.showConfirmationSheet()
                self.setLicensedValues()
            } else {
                log.error("Result: License code is invalid.")
                self.showErrorSheet(messageText: "License code invalid",
                                    informativeText: "The combination of name, company, email and license code you entered is invalid.\n\nMake sure to enter the information exactly as you did when purchasing.")
            }
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

        if AppState.isLicensed {
            self.setLicensedValues()
        } else {
            self.setUnlicensedValues()
        }
        
        if !AppState.isLicensed && !AppState.isInEvaluation {
            self.showPurchaseSheet()
        }
    }
    
    func setLicensedValues() {
        self.regEvalStatusTextField.stringValue = AppState.regEvalStatus
        self.purchaseButton.isHidden = true
        
        self.nameTextField.stringValue = userDefaults.string(forKey: UserDefaultStruct.regName)!
        self.companyTextField.stringValue = userDefaults.string(forKey: UserDefaultStruct.regCompany)!
        self.emailTextField.stringValue = userDefaults.string(forKey: UserDefaultStruct.regEmail)!
        self.licenseCodeTextField.stringValue = userDefaults.string(forKey: UserDefaultStruct.regLicenseCode)!
        
        self.nameTextField.isEditable = false
        self.companyTextField.isEditable = false
        self.emailTextField.isEditable = false
        self.licenseCodeTextField.isEditable = false
        
        self.nameTextField.isSelectable = false
        self.companyTextField.isSelectable = false
        self.emailTextField.isSelectable = false
        self.licenseCodeTextField.isSelectable = false  // doesn't really work.
        
        let dimmedTextColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        self.nameTextField.textColor = dimmedTextColor
        self.companyTextField.textColor = dimmedTextColor
        self.emailTextField.textColor = dimmedTextColor
        self.licenseCodeTextField.textColor = dimmedTextColor
        
        self.applyButton.title = "Remove License"
    }
    
    func setUnlicensedValues() {
        self.regEvalStatusTextField.stringValue = AppState.regEvalStatus
        self.purchaseButton.isHidden = false
        
        self.nameTextField.stringValue = ""
        self.companyTextField.stringValue = ""
        self.emailTextField.stringValue = ""
        self.licenseCodeTextField.stringValue = ""
        
        self.nameTextField.isEditable = true
        self.companyTextField.isEditable = true
        self.emailTextField.isEditable = true
        self.licenseCodeTextField.isEditable = true
        
        self.nameTextField.isSelectable = true
        self.companyTextField.isSelectable = true
        self.emailTextField.isSelectable = true
        self.licenseCodeTextField.isSelectable = true
        
        let undimmedTextColor: NSColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        self.nameTextField.textColor = undimmedTextColor
        self.companyTextField.textColor = undimmedTextColor
        self.emailTextField.textColor = undimmedTextColor
        self.licenseCodeTextField.textColor = undimmedTextColor
        
        self.applyButton.title = "Check License"
    }
    
    func reopenPurchaseSheet(notification: Notification?) {
        let parentWindow = self.view.window!
        if parentWindow.sheets.count == 0 {
            self.showPurchaseSheet()
        }
    }
    
    func showPurchaseSheet() {
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
    
    func getRegName() -> String {
        let name: String = self.nameTextField.stringValue
        let company: String = self.companyTextField.stringValue
        let email: String = self.emailTextField.stringValue
        let regName = generateRegName(name: name, company: company, email: email)
        log.debug("Entered registration name: " + regName)
        return regName
    }
    
    func showConfirmationSheet() {
        let validAlert = NSAlert()
        validAlert.showsHelp = false
        validAlert.messageText = "Thank you for purchasing DropPy"
        validAlert.informativeText = "You are now registered."
        validAlert.addButton(withTitle: "Ok")
        validAlert.layout()
        validAlert.icon = NSImage(named: "confirmation")
        validAlert.beginSheetModal(for: self.view.window!)
    }
    
    func showErrorSheet(messageText: String, informativeText: String) {
        let invalidAlert = NSAlert()
        invalidAlert.showsHelp = false
        invalidAlert.messageText = messageText
        invalidAlert.informativeText = informativeText
        invalidAlert.addButton(withTitle: "Ok")
        invalidAlert.layout()
        invalidAlert.icon = NSImage(named: "error")
        invalidAlert.beginSheetModal(for: self.view.window!)
    }
    
    func showRemoveSheet() {
        let removeAlert = NSAlert()
        removeAlert.showsHelp = false
        removeAlert.messageText = "Remove License"
        removeAlert.informativeText = "Are you sure you want to remove the entered license information from this machine?"
        removeAlert.addButton(withTitle: "Remove")
        removeAlert.addButton(withTitle: "Cancel")
        removeAlert.layout()
        removeAlert.alertStyle = NSAlertStyle.critical
        removeAlert.icon = NSImage(named: "alert")
        
        removeAlert.beginSheetModal(for: NSApplication.shared().mainWindow!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSAlertFirstButtonReturn {
                self.clearRegValues()
                self.setUnlicensedValues()
            }
        })
    }
    
    func saveRegValues() {
        let name: String = self.nameTextField.stringValue
        userDefaults.set(name, forKey: UserDefaultStruct.regName)
        
        let company: String = self.companyTextField.stringValue
        userDefaults.set(company, forKey: UserDefaultStruct.regCompany)
        
        let email: String = self.emailTextField.stringValue
        userDefaults.set(email, forKey: UserDefaultStruct.regEmail)
        
        let licenseCode = self.licenseCodeTextField.stringValue
        userDefaults.set(licenseCode, forKey: UserDefaultStruct.regLicenseCode)
        
        AppState.regEvalStatus = "Licensed ❤️"
        AppState.isLicensed = true
    }
    
    func clearRegValues() {
        userDefaults.removeObject(forKey: UserDefaultStruct.regName)
        userDefaults.removeObject(forKey: UserDefaultStruct.regCompany)
        userDefaults.removeObject(forKey: UserDefaultStruct.regEmail)
        userDefaults.removeObject(forKey: UserDefaultStruct.regLicenseCode)
        
        _ = isInEvaluation()  // this updates AppState.regEvalStatus.
        AppState.isLicensed = false
    }
    
    func validateInput() -> Bool {
        let name: String = self.nameTextField.stringValue
        if name.characters.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "Name cannot be empty.")
            return false
        }
        
        let email: String = self.emailTextField.stringValue
        if email.characters.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "Email cannot be empty.")
            return false
        }
        
        let licenseCode = self.licenseCodeTextField.stringValue
        if licenseCode.characters.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "License code cannot be empty.")
            return false
        }
        
        return true
    }
}
