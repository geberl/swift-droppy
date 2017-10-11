//
//  Update.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import os.log


enum JsonError: Error {
    case misformed
}


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
        DispatchQueue.main.async { if !silent { NotificationCenter.default.post(name: .updateError, object: nil) } }
        return
    } else {
        os_log("Network connection available, attempting to download 'version.json' file.", log: logUpdate, type: .info)
    }
    
    os_log("URL: '%@'.", log: logUpdate, type: .info, droppyappUrls.versionJson!.absoluteString)
    
    let urlSession = URLSession(configuration: URLSessionConfiguration.default)
    let task = urlSession.dataTask(with: droppyappUrls.versionJson!) {data, response, error in
        guard error == nil else {
            os_log("%@", log: logUpdate, type: .error, (error?.localizedDescription)!)
            DispatchQueue.main.async { if !silent { NotificationCenter.default.post(name: .updateError, object: nil) } }
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 {
                os_log("File not found (status code 404).", log: logUpdate, type: .error)
                DispatchQueue.main.async { if !silent { NotificationCenter.default.post(name: .updateError, object: nil) } }
                return
            } else if httpResponse.statusCode == 200 {
                os_log("File downloaded (status code 200).", log: logUpdate, type: .info)
            } else {
                os_log("Unexpected response of server (status code %d).", log: logUpdate, type: .info,
                       httpResponse.statusCode)
            }
        }
        
        guard let data = data else {
            os_log("Content of data is nil.", log: logUpdate, type: .error)
            DispatchQueue.main.async { if !silent { NotificationCenter.default.post(name: .updateError, object: nil) } }
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject]
            
            guard let versionMajor = json["versionMajor"] as? Int else { throw JsonError.misformed}
            guard let versionMinor = json["versionMinor"] as? Int else { throw JsonError.misformed}
            guard let versionPatch = json["versionPatch"] as? Int else { throw JsonError.misformed}
            guard let releaseNotes = json["releaseNotes"] as? String else { throw JsonError.misformed}
            guard let downloadLink = json["downloadLink"] as? String else { throw JsonError.misformed}
            
            let versionDict:[String: String] = ["versionString": String(versionMajor) + "." + String(versionMinor) + "." + String(versionPatch),
                                                "releaseNotesLink": releaseNotes,
                                                "downloadLink": downloadLink]
            
            DispatchQueue.main.async {
                if isLatestVersion(webVersionMajor: versionMajor,
                                   webVersionMinor: versionMinor,
                                   webVersionPatch: versionPatch) {
                    os_log("Result: No update available.", log: logUpdate, type: .info)
                    if !silent {
                        NotificationCenter.default.post(name: .updateNotAvailable, object: nil, userInfo: versionDict)
                    }
                } else {
                    os_log("Result: Update available. Showing dialog.", log: logUpdate, type: .info)
                    NotificationCenter.default.post(name: .updateAvailable, object: nil, userInfo: versionDict)
                }
            }
        } catch let error {
            os_log("%@", log: logUpdate, type: .error, error.localizedDescription)
            os_log("JSON doesn't have the expected structure.", log: logUpdate, type: .error)
            DispatchQueue.main.async { if !silent { NotificationCenter.default.post(name: .updateError, object: nil) } }
            return
        }
    }
    task.resume()
    
    let userDefaults = UserDefaults.standard
    userDefaults.set(Date(), forKey: UserDefaultStruct.updateLast)
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
