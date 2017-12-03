//
//  ViewControllerRegistration.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerRegistration: NSViewController {
    
    let userDefaults = UserDefaults.standard

    @IBOutlet weak var regTrialStatusTextField: NSTextField!
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var companyTextField: NSTextField!
    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var licenseCodeTextField: NSTextField!
    @IBOutlet weak var purchaseButton: NSButton!
    @IBOutlet weak var applyButton: NSButton!

    @IBAction func onPurchaseButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.main)
    }
    
    @IBAction func onApplyButton(_ sender: NSButton) {
        if AppState.isLicensed {
            os_log("Removing license info.", log: logLicense, type: .info)
            self.showRemoveSheet()
        } else {
            os_log("Checking license info.", log: logLicense, type: .info)
            
            if !self.validateInput() {
                os_log("Input invalid.", log: logLicense, type: .error)
                return
            }
            
            let licenseCode = self.licenseCodeTextField.stringValue
            os_log("Entered license code: %@.", log: logLicense, type: .info, licenseCode)
            
            let validLicense: Bool = checkValidLicense(licenseCode: licenseCode, regName: self.getRegName())
            if validLicense {
                os_log("Result: License code is valid.", log: logLicense, type: .info)
                self.saveRegValues()
                self.showConfirmationSheet()
                self.setLicensedValues()
            } else {
                os_log("Result: License code is invalid.", log: logLicense, type: .error)
                self.showErrorSheet(messageText: "License code invalid",
                                    informativeText: "The combination of name, company, email and license code you entered is invalid.\n\nMake sure to enter the information exactly as you did when purchasing.")
            }
        }
    }
    
    @IBAction func onCloseButton(_ sender: NSButton) {
        NotificationCenter.default.post(name: .closeRegistration, object: nil)
    }
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerRegistration.reopenPurchaseSheet),
                                               name: .reopenPurchaseSheet, object: nil)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        if AppState.isLicensed {
            self.setLicensedValues()
        } else {
            self.setUnlicensedValues()
        }
        
        if !AppState.isLicensed && !AppState.isInTrial {
            self.showPurchaseSheet()
        }
    }
    
    func setLicensedValues() {
        self.regTrialStatusTextField.stringValue = AppState.regTrialStatus
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
        self.regTrialStatusTextField.stringValue = AppState.regTrialStatus
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
    
    @objc func reopenPurchaseSheet(_ notification: Notification?) {
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
        purchaseAlert.icon = NSImage(named: NSImage.Name(rawValue: "AppIcon"))
        purchaseAlert.beginSheetModal(for: self.view.window!, completionHandler: self.showPurchaseSheetCompletion)
    }
    
    func showPurchaseSheetCompletion(userChoice: NSApplication.ModalResponse) {
        if userChoice == NSApplication.ModalResponse.alertFirstButtonReturn {
            openWebsite(webUrl: droppyappUrls.main)
        }
    }
    
    func getRegName() -> String {
        let name: String = self.nameTextField.stringValue
        let company: String = self.companyTextField.stringValue
        let email: String = self.emailTextField.stringValue
        let regName = generateRegName(name: name, company: company, email: email)
        os_log("Registered for: %@.", log: logLicense, type: .info, regName)
        return regName
    }
    
    func showConfirmationSheet() {
        let validAlert = NSAlert()
        validAlert.showsHelp = false
        validAlert.messageText = "Thank you for purchasing DropPy"
        validAlert.informativeText = "You are now registered."
        validAlert.addButton(withTitle: "Ok")
        validAlert.layout()
        validAlert.icon = NSImage(named: NSImage.Name(rawValue: "confirmation"))
        validAlert.beginSheetModal(for: self.view.window!)
    }
    
    func showErrorSheet(messageText: String, informativeText: String) {
        let invalidAlert = NSAlert()
        invalidAlert.showsHelp = false
        invalidAlert.messageText = messageText
        invalidAlert.informativeText = informativeText
        invalidAlert.addButton(withTitle: "Ok")
        invalidAlert.layout()
        invalidAlert.icon = NSImage(named: NSImage.Name(rawValue: "error"))
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
        removeAlert.alertStyle = NSAlert.Style.critical
        removeAlert.icon = NSImage(named: NSImage.Name(rawValue: "alert"))
        
        removeAlert.beginSheetModal(for: NSApplication.shared.mainWindow!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
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
        
        AppState.regTrialStatus = "Licensed ❤️"
        AppState.isLicensed = true
    }
    
    func clearRegValues() {
        userDefaults.removeObject(forKey: UserDefaultStruct.regName)
        userDefaults.removeObject(forKey: UserDefaultStruct.regCompany)
        userDefaults.removeObject(forKey: UserDefaultStruct.regEmail)
        userDefaults.removeObject(forKey: UserDefaultStruct.regLicenseCode)
        
        _ = isInTrial()  // this updates AppState.regTrialStatus.
        AppState.isLicensed = false
    }
    
    func validateInput() -> Bool {
        let name: String = self.nameTextField.stringValue
        if name.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "Name cannot be empty.")
            return false
        }
        
        let email: String = self.emailTextField.stringValue
        if email.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "Email cannot be empty.")
            return false
        }
        
        let licenseCode = self.licenseCodeTextField.stringValue
        if licenseCode.count == 0 {
            self.showErrorSheet(messageText: "Input invalid",
                                informativeText: "License code cannot be empty.")
            return false
        }
        
        return true
    }
}
