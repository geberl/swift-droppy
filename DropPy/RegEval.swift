//
//  RegEval.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import CommonCrypto

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


func beginEvaluation() {
    let userDefaults = UserDefaults.standard
    
    let evalStartDate: Date = Date()
    userDefaults.set(evalStartDate, forKey: UserDefaultStruct.evalStartDate)
    
    let evalStartString: String = evalStartDate.iso8601 + "_" + AppState.evalStartSalt
    let evalStartHash = evalStartString.sha512()
    userDefaults.set(evalStartHash, forKey: UserDefaultStruct.evalStartHash)
    
    let evalEndDate: Date = evalStartDate.addingTimeInterval(60 * 60 * 24 * 7 * 2)  // 14 days
    
    AppState.isInEvaluation = true
    log.info("Evaluation period started at " + evalStartDate.readable + " (ends at " + evalEndDate.readable + ").")
}


func isInEvaluation() -> Bool {
    let userDefaults = UserDefaults.standard
    guard let evalStartDate: Date = userDefaults.object(forKey: UserDefaultStruct.evalStartDate) as? Date else { return false }
    guard let evalStartHashSaved: Data = userDefaults.data(forKey: UserDefaultStruct.evalStartHash) else { return false }
    
    let nowDate: Date = Date()
    let evalEndDate: Date = evalStartDate.addingTimeInterval(60 * 60 * 24 * 7 * 2)  // 14 days
    
    // Check if evalStartDate is still valid against evalStartHash.
    let evalStartStringNew: String = evalStartDate.iso8601 + "_" + AppState.evalStartSalt
    let evalStartHashNew: Data = evalStartStringNew.sha512()
    if evalStartHashSaved != evalStartHashNew {
        log.info("Evaluation period ended (evalStartHash invalid for evalStartDate).")
        return false
    }
    
    // Check if now is before the evaluation's start date.
    if nowDate < evalStartDate {
        log.info("Evaluation period ended (now is before evalStartDate).")
        return false
    }
    
    // Check if now is after the evaluation's end date.
    if nowDate > evalEndDate {
        log.info("Evaluation period ended at " + evalEndDate.readable + " (started at " + evalStartDate.readable + ").")
        return false
    }
    
    // Product is still in evaluation.
    log.info("Evaluation period active, will end at " + evalEndDate.readable + " (started at " + evalStartDate.readable + ").")
    return true
}

func isLicensed() -> Bool {
    // TODO implement
    return false
}
