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
    @IBOutlet weak var applyButton: NSButton!
    @IBOutlet weak var firstNameTextField: NSTextField!
    @IBOutlet weak var keyTextField: NSTextField!
    
    @IBAction func onPurchaseButton(_ sender: NSButton) {
        self.openPurchaseWebsite()
    }
    
    @IBAction func onApplyButton(_ sender: NSButton) {
        if AppState.isLicensed {
            log.debug("TODO: remove license info now")
            // TODO slide open a page to confirm (yes/no buttons)
            // TODO update userDefaults and AppState if confirmed
        } else {
            log.debug("TODO: check license info now")
            // TODO check and slide open a page either reporting an error or thanking the user for his purchase (just with an ok button that closes it again)
            // TODO update userDefaults and AppState if successful
            
            let firstName: String = self.firstNameTextField.stringValue
            let key: String = self.keyTextField.stringValue
            let publicKey: String = self.publicKey()
            let privateKey: String = self.privateKey()
            var validLicense: Bool = false
            var licenseCode: String? = nil
            
            log.debug("firstName: " + firstName)
            log.debug("key: " + key)
            
            if let verifier = verifierWithPublicKey(publicKey) {
                log.error("Running LicenseVerifier")
                validLicense = verifier.verify(key, forName: firstName)
            } else {
                log.error("LicenseVerifier cannot be constructed")
                validLicense = false
            }
            
            log.debug("validLicense: " + "\(validLicense)")
            
            if let generator = generatorWithPrivateKey(privateKey) {
                log.error("Running LicenseGenerator")
                do {
                    try licenseCode = generator.generate(firstName)
                } catch {
                    log.error("Some error occured")
                }
            } else {
                log.error("LicenseGenerator cannot be constructed")
                licenseCode = nil
            }
            
            log.debug("licenseCode: " + "\(licenseCode ?? "n/a")")
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
    
    fileprivate func publicKey() -> String {
        var parts = [String]()
        parts.append("-----BEGIN PUBLIC KEY-----\n")
        parts.append("MIHwMIGoBgcqhkjOOAQBMIGcAkEA0na+2HrZFpHgSuPt3URJHdi1ZdYV")
        parts.append("LmynsU6hlJCc6ls1SEMAfvreHI2wjPLYsp/uGdry80fAfzJzc6sbAWAS")
        parts.append("WwIVAM8C9fTNlz2UG0s7cxBhwvZ/YQ2TAkAEq2QWgNT3PmjOBni47BF9")
        parts.append("z1BvfDihZgXapbTS/VoX2IRGPAqJD5z3n63DcP2/HR85OpAnh5EoJ2+A")
        parts.append("1KP+7PmPA0MAAkB6EewxQwgHzP57HuC2h1we7VxcsqoyiXofL9ADxSPf")
        parts.append("9CMfYDJVFgjiWGMEIui9a4GaPYl1EHPxilgYfDHJ0HtT")
        parts.append("-----END PUBLIC KEY-----\n")
        return parts.joined(separator: "")
    }
    
    fileprivate func privateKey() -> String {
        var parts = [String]()
        parts.append("-----BEGIN DSA PRIVATE KEY-----\n")
        parts.append("MIH4AgEAAkEA0na+2HrZFpHgSuPt3URJHdi1ZdYVLmynsU6hlJCc6ls1")
        parts.append("SEMAfvreHI2wjPLYsp/uGdry80fAfzJzc6sbAWASWwIVAM8C9fTNlz2U")
        parts.append("G0s7cxBhwvZ/YQ2TAkAEq2QWgNT3PmjOBni47BF9z1BvfDihZgXapbTS")
        parts.append("/VoX2IRGPAqJD5z3n63DcP2/HR85OpAnh5EoJ2+A1KP+7PmPAkB6Eewx")
        parts.append("QwgHzP57HuC2h1we7VxcsqoyiXofL9ADxSPf9CMfYDJVFgjiWGMEIui9")
        parts.append("a4GaPYl1EHPxilgYfDHJ0HtTAhUAsWZBduv3aFnYiRBii/R2CXQhoTg=")
        parts.append("-----END DSA PRIVATE KEY-----\n")
        return parts.joined(separator: "")
    }
    
    fileprivate func verifierWithPublicKey(_ publicKey: String) -> LicenseVerifier? {
        return LicenseVerifier(publicKeyPEM: publicKey)
    }
    
    fileprivate func generatorWithPrivateKey(_ privateKey: String) -> LicenseGenerator? {
        return LicenseGenerator(privateKeyPEM: privateKey)
    }
}
