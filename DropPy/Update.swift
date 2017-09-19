//
//  Update.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation


func autoUpdate() {
    let userDefaults = UserDefaults.standard
    let updateDelta: Int = userDefaults.integer(forKey: UserDefaultStruct.updateDelta)
    let updateLast: Date = userDefaults.object(forKey: UserDefaultStruct.updateLast) as! Date
    let updateNext: Date = updateLast.addingTimeInterval(TimeInterval(updateDelta))
    let dateNow: Date = Date()
    
    if dateNow > updateNext {
        manualUpdate(silent: true)
    } else {
        log.info("Not checking for updates now, next check " + updateNext.readable + ".")
    }
}


func manualUpdate(silent: Bool) {
    if !isConnectedToNetwork() {
        log.debug("No network connection available, skipping update check.")
        if !silent {
            NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
        }
        return
    }
    
    let userDefaults = UserDefaults.standard
    userDefaults.set(Date(), forKey: UserDefaultStruct.updateLast)
    
    let jsonURL = URL(string: "https://droppyapp.com/version.json")
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    let task = urlSession.dataTask(with: jsonURL!) {data, response, error in
        guard error == nil else {
            log.error("Checking for updates: Server did not respond.")
            log.error((error?.localizedDescription)!)
            DispatchQueue.main.async {
                if !silent {
                    NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
                }
            }
            return
        }
        
        guard let data = data else {
            log.error("Checking for updates: Response of server is empty.")
            DispatchQueue.main.async {
                if !silent {
                    NotificationCenter.default.post(name: Notification.Name("updateError"), object: nil)
                }
            }
            return
        }
        
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
        let versionMajor = json["versionMajor"] as! Int
        let versionMinor = json["versionMinor"] as! Int
        let versionPatch = json["versionPatch"] as! Int
        let versionDict:[String: String] = ["versionString": String(versionMajor) + "." + String(versionMinor) + "." + String(versionPatch),
                                            "releaseNotesLink": json["releaseNotes"] as! String,
                                            "downloadLink": json["download"] as! String]
        
        DispatchQueue.main.async {
            if isLatestVersion(webVersionMajor: versionMajor,
                               webVersionMinor: versionMinor,
                               webVersionPatch: versionPatch) {
                log.info("Checking for updates: No update available.")
                if !silent {
                    NotificationCenter.default.post(name: Notification.Name("updateNotAvailable"),
                                                    object: nil,
                                                    userInfo: versionDict)
                }
            } else {
                log.info("Checking for updates: Update available.")
                NotificationCenter.default.post(name: Notification.Name("updateAvailable"),
                                                object: nil,
                                                userInfo: versionDict)
            }
        }
    }
    task.resume()
}


func isLatestVersion(webVersionMajor: Int, webVersionMinor: Int, webVersionPatch: Int) -> Bool {
    if let thisVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        let thisVersionList: [String] = thisVersion.components(separatedBy: ".")
        let thisVersionMajor: Int = Int(thisVersionList[0])!
        let thisVersionMinor: Int = Int(thisVersionList[1])!
        let thisVersionPatch: Int = Int(thisVersionList[2])!
        
        if webVersionMajor > thisVersionMajor {
            return false
        } else if webVersionMinor > thisVersionMinor {
            return false
        } else if webVersionPatch > thisVersionPatch {
            return false
        }
    } else {
        log.error("Can't get version string from plist.")
    }
    return true
}
