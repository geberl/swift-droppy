//
//  RegTrial.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import CommonCrypto
import os.log

// Prerequisites for importing CommonCrypto:
// In your project setup Apple's CommonCrypto C library like described at https://stackoverflow.com/a/29189873/8137043
// The config files might need updating after the target changes for example from macOS 10.12 to 10.13


struct Sha512 {
    // Source: https://stackoverflow.com/a/44855370/8137043
    let context = UnsafeMutablePointer<CC_SHA512_CTX>.allocate(capacity:1)

    init() {
        CC_SHA512_Init(context)
    }

    func update(data: Data) {
        data.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Void in
            let end = bytes.advanced(by: data.count)
            for f in sequence(first: bytes, next: { $0.advanced(by: Int(CC_LONG.max)) }).prefix(while: { (current) -> Bool in current < end})  {
                _ = CC_SHA512_Update(context, f, CC_LONG(Swift.min(f.distance(to: end), Int(CC_LONG.max))))
            }
        }
    }

    func final() -> Data {
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA512_DIGEST_LENGTH))
        CC_SHA512_Final(&digest, context)
        return Data(bytes: digest)
    }
}


extension Data {
    func sha512() -> Data {
        let s = Sha512()
        s.update(data: self)
        return s.final()
    }
}


extension String {
    func sha512() -> Data {
        return self.data(using: .utf8)!.sha512()
    }
}


func shaDataToString(shaData: Data) -> String {
    // Source: https://stackoverflow.com/questions/39616821/swift-3-0-data-to-string
    let shaNsData = NSData.init(data: shaData)

    var dataString = shaNsData.description
    dataString = dataString.replacingOccurrences(of: " ", with: "")
    dataString = dataString.replacingOccurrences(of: "<", with: "")
    dataString = dataString.replacingOccurrences(of: ">", with: "")

    return dataString
}


func beginTrial() {
    let userDefaults = UserDefaults.standard
    
    let trialStartDate: Date = Date()
    userDefaults.set(trialStartDate, forKey: UserDefaultStruct.trialStartDate)
    
    let trialStartString: String = "\(trialStartDate.timeIntervalSince1970)" + "_" + AppState.trialStartSalt
    let trialStartHash = trialStartString.sha512()
    userDefaults.set(trialStartHash, forKey: UserDefaultStruct.trialStartHash)
    
    let trialEndDate: Date = trialStartDate.addingTimeInterval(60 * 60 * 24 * 7 * 2)  // 14 days
    
    AppState.isInTrial = true
    AppState.regTrialStatus = "Unlicensed (Trial ends on " + trialEndDate.readableDate + ")"
    os_log("Trial period started at %@ (ends at %@).", log: logLicense, type: .info,
           trialStartDate.readable, trialEndDate.readable)
}


func isInTrial() -> Bool {
    let userDefaults = UserDefaults.standard
    guard let trialStartDate: Date = userDefaults.object(forKey: UserDefaultStruct.trialStartDate) as? Date else { return false }
    guard let trialStartHashSaved: Data = userDefaults.data(forKey: UserDefaultStruct.trialStartHash) else { return false }
    
    let nowDate: Date = Date()
    let trialEndDate: Date = trialStartDate.addingTimeInterval(60 * 60 * 24 * 7 * 2)  // 14 days
    
    // Check if trialStartDate is still valid against trialStartHash.
    let trialStartStringNew: String = "\(trialStartDate.timeIntervalSince1970)" + "_" + AppState.trialStartSalt
    let trialStartHashNew: Data = trialStartStringNew.sha512()
    if trialStartHashSaved != trialStartHashNew {
        AppState.regTrialStatus = "Unlicensed (Trial ended)"
        os_log("Trial period ended (trialStartHash invalid for trialStartDate).", log: logLicense, type: .error)
        return false
    }
    
    // Check if now is before the trial's start date.
    if nowDate < trialStartDate {
        AppState.regTrialStatus = "Unlicensed (Trial ended)"
        os_log("Trial period ended (now is before trialStartDate).", log: logLicense, type: .error)
        return false
    }
    
    // Check if now is after the trial's end date.
    if nowDate > trialEndDate {
        AppState.regTrialStatus = "Unlicensed (Trial ended on " + trialEndDate.readableDate + ")"
        os_log("Trial period over (ended at %@, started at %@).", log: logLicense, type: .info,
               trialEndDate.readable, trialStartDate.readable)
        return false
    }
    
    // Product is still in trial.
    AppState.regTrialStatus = "Unlicensed (Trial ends on " + trialEndDate.readableDate + ")"
    os_log("Trial period active (will end at %@, started at %@).", log: logLicense, type: .info,
           trialEndDate.readable, trialStartDate.readable)
    return true
}

func generateRegName(name: String, company: String, email: String) -> String {
    let product: String = "DropPy"  // needed so a user doesn't get a license code that works on all your product when he buys one.
    let regName = product + "|" + name + "|" + email + "|" + company
    return regName
}

func isLicensed() -> Bool {
    let userDefaults = UserDefaults.standard
    guard let name: String = userDefaults.string(forKey: UserDefaultStruct.regName) else { return false }
    guard let company: String = userDefaults.string(forKey: UserDefaultStruct.regCompany) else { return false }
    guard let email: String = userDefaults.string(forKey: UserDefaultStruct.regEmail) else { return false }
    guard let licenseCode = userDefaults.string(forKey: UserDefaultStruct.regLicenseCode) else { return false }

    let regName = generateRegName(name: name, company: company, email: email)
    let validLicense: Bool = checkValidLicense(licenseCode: licenseCode, regName: regName)
    if validLicense {
        os_log("Valid license found.", log: logLicense, type: .info)
        AppState.regTrialStatus = "Licensed ❤️"
        return true
    } else {
        os_log("No valid license found.", log: logLicense, type: .error)
        return false
    }
}

fileprivate func publicKey() -> String {
    var parts = [String]()
    parts.append("-----BEGIN PUBLIC KEY-----\n")
    parts.append("MIHwMIGoBgcqhkjOOAQBMIGcAkEA0na+2HrZFpHgSuPt3URJHdi1ZdYV\n")
    parts.append("LmynsU6hlJCc6ls1SEMAfvreHI2wjPLYsp/uGdry80fAfzJzc6sbAWAS\n")
    parts.append("WwIVAM8C9fTNlz2UG0s7cxBhwvZ/YQ2TAkAEq2QWgNT3PmjOBni47BF9\n")
    parts.append("z1BvfDihZgXapbTS/VoX2IRGPAqJD5z3n63DcP2/HR85OpAnh5EoJ2+A\n")
    parts.append("1KP+7PmPA0MAAkB6EewxQwgHzP57HuC2h1we7VxcsqoyiXofL9ADxSPf\n")
    parts.append("9CMfYDJVFgjiWGMEIui9a4GaPYl1EHPxilgYfDHJ0HtT\n")
    parts.append("-----END PUBLIC KEY-----\n")
    return parts.joined(separator: "")
}

fileprivate func verifierWithPublicKey(_ publicKey: String) -> LicenseVerifier? {
    return LicenseVerifier(publicKeyPEM: publicKey)
}

func checkValidLicense(licenseCode: String, regName: String) -> Bool {
    var validLicense: Bool = false
    if let verifier = verifierWithPublicKey(publicKey()) {
        validLicense = verifier.verify(licenseCode, forName: regName)
    } else {
        os_log("LicenseVerifier could not be constructed.", log: logLicense, type: .error)
    }
    return validLicense
}
