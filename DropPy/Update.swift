//
//  Update.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import os.log


func autoUpdate() {
    let userDefaults = UserDefaults.standard
    let updateDelta: Int = userDefaults.integer(forKey: UserDefaultStruct.updateDelta)
    let updateLast: Date = userDefaults.object(forKey: UserDefaultStruct.updateLast) as! Date
    let updateNext: Date = updateLast.addingTimeInterval(TimeInterval(updateDelta))
    let dateNow: Date = Date()
    
    if dateNow > updateNext {
        manualUpdate(silent: true)
    } else {
        os_log("Not checking for updates now, next check %@.", log: logUpdate, type: .info, updateNext.readable)
    }
}


func manualUpdate(silent: Bool) {
    if !isConnectedToNetwork() {
        os_log("No network connection available, skipping update check.", log: logUpdate, type: .info)
        if !silent {
            NotificationCenter.default.post(name: .updateError, object: nil)
        }
        return
    }
    
    let userDefaults = UserDefaults.standard
    userDefaults.set(Date(), forKey: UserDefaultStruct.updateLast)
    
    let jsonURL = URL(string: "https://droppyapp.com/version.json")
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    let task = urlSession.dataTask(with: jsonURL!) {data, response, error in
        guard error == nil else {
            os_log("%@", log: logDrop, type: .error, (error?.localizedDescription)!)
            os_log("Checking for updates: Server did not respond.", log: logUpdate, type: .info)
            DispatchQueue.main.async {
                if !silent {
                    NotificationCenter.default.post(name: .updateError, object: nil)
                }
            }
            return
        }
        
        guard let data = data else {
            os_log("Checking for updates: Response of server is empty.", log: logUpdate, type: .error)
            DispatchQueue.main.async {
                if !silent {
                    NotificationCenter.default.post(name: .updateError, object: nil)
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
                os_log("Checking for updates: No update available.", log: logUpdate, type: .info)
                if !silent {
                    NotificationCenter.default.post(name: .updateNotAvailable, object: nil, userInfo: versionDict)
                }
            } else {
                os_log("Checking for updates: Update available.", log: logUpdate, type: .info)
                NotificationCenter.default.post(name: .updateAvailable, object: nil, userInfo: versionDict)
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
        os_log("Can't get version string from plist.", log: logUpdate, type: .error)
    }
    return true
}
