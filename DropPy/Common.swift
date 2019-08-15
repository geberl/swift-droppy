//
//  Common.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SystemConfiguration
import os.log


func isDir(path: String) -> Bool {
    let fileUrl = URL(fileURLWithPath: path)
    if let values = try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]) {
        if values.isDirectory! {
            return true  // a directory.
        } else {
            return false  // a file.
        }
    }
    return false  // path not accessible at all.
}


func isFile(path: String) -> Bool {
    let fileUrl = URL(fileURLWithPath: path)
    if let values = try? fileUrl.resourceValues(forKeys: [.isDirectoryKey]) {
        if values.isDirectory! {
            return false  // not a file but a directory.
        } else {
            return true  // a file.
        }
    }
    return false  // path not accessible at all.
}


func makeDirs(path: String) {
    let fileManager = FileManager.default
    do {
        try fileManager.createDirectory(atPath: path,
                                        withIntermediateDirectories: true,
                                        attributes: nil)
        os_log("Created dir '%@'.", log: logFileSystem, type: .debug, path)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
}


func removeDir(path: String) {
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: path)
        os_log("Removed dir '%@'.", log: logFileSystem, type: .debug, path)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
}


func copyDir(sourceDirPath: String, targetDirPath: String) {
    let fileManager = FileManager.default
    do {
        try fileManager.copyItem(at: URL(fileURLWithPath: sourceDirPath),
                                 to: URL(fileURLWithPath: targetDirPath))
        os_log("Copied dir from '%@' to '%@.", log: logFileSystem, type: .debug, sourceDirPath, targetDirPath)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
}


func trashDirOrFile(path: String) {
    let fileManager = FileManager.default
    do {
        try fileManager.trashItem(at: URL(fileURLWithPath: path),
                                  resultingItemURL: nil)
        os_log("Deleted item to trash '%@.", log: logFileSystem, type: .debug, path)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
}


func executeCommand(command: String, args: [String], setEnv: Bool = true, debug: Bool = false) -> (output: [String], error: [String], exit: Int32) {
    // Source: https://stackoverflow.com/questions/29514738/get-terminal-output-after-a-command-swift#29519615
    
    var output: [String] = []
    var error: [String] = []
    var exit: Int32
    
    if isFile(path: command) {
        
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
        if setEnv {
            task.environment = ["LC_ALL":           "en_US.UTF-8",
                                "LC_CTYPE":         "en_US.UTF-8",
                                "LANG":             "en_US.UTF-8",
                                "PYTHONIOENCODING": "utf8"]
        }
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        exit = task.terminationStatus

    } else {
        error.append("Command not found")
        error.append(command)
        exit = 1
    }
    
    if debug {
        os_log("Command Output '%@'", log: logFileSystem, type: .debug, output)
        os_log("Command Error  '%@'", log: logFileSystem, type: .debug, error)
        os_log("Command Exit   '%@'", log: logFileSystem, type: .debug, exit)
    }
    
    return (output, error, exit)
}


func isConnectedToNetwork() -> Bool {
    // Source: https://stackoverflow.com/questions/25398664/check-for-internet-connection-availability-in-swift
    var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)

    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }

    var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
    if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
        return false
    }

    let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
    let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
    let ret = (isReachable && !needsConnection)

    return ret
}


func createWorkspaceDirStructure(workspacePath: String) {
    if !isDir(path: workspacePath + "/" + "Images") {
        makeDirs(path: workspacePath + "/" + "Images")
    }
    if !isDir(path: workspacePath + "/" + "Tasks") {
        makeDirs(path: workspacePath + "/" + "Tasks")
    }
    if !isDir(path: workspacePath + "/" + "Workflows") {
        makeDirs(path: workspacePath + "/" + "Workflows")
    }
}


func extractBundledWorkspace(workspacePath: String) {
    let fileManager = FileManager.default
    
    // Set temp directory and file, remove it if it already exists.
    let tempPath: String = NSTemporaryDirectory() + "se.eberl.droppy" + "/"
    makeDirs(path: tempPath)
    
    let zipPath: String = tempPath + "droppy-workspace-temp.zip"
    if isFile(path: zipPath) {
        do {
            try fileManager.removeItem(atPath: zipPath)
        } catch let error {
            os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
        }
    }
    
    let unzipPath: String = tempPath + "droppy-workspace-temp" + "/"
    if isDir(path: unzipPath) {
        do {
            try fileManager.removeItem(atPath: unzipPath)
        } catch let error {
            os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
        }
    }

    // Copy content of asset bundled-droppy-workspace to the temp directory as droppy-workspace-temp.zip.
    if let asset = NSDataAsset(name: "bundled-droppy-workspace", bundle: Bundle.main) {
        do {
            try asset.data.write(to: URL(fileURLWithPath: zipPath))
            os_log("Copied bundled asset to '%@'.", log: logFileSystem, type: .debug, zipPath)
        } catch let error {
            os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
        }
    }
    
    // Unzip the zip file into the dedicated temp directory.
    //SSZipArchive.unzipFile(atPath: zipPath, toDestination: unzipPath) // TODO removed cocoapod
    //os_log("Unzipped '%@' to '%@'.", log: logFileSystem, type: .debug, zipPath, unzipPath)
    os_log("TODO actually unzip now", log: logFileSystem, type: .error)
    
    // The zip file contains a sub-directory. Find out its name (depends on release version of Workspace).
    guard let subDirEnumerator: FileManager.DirectoryEnumerator =
        fileManager.enumerator(atPath: unzipPath) else {
            os_log("Directory not found at '%@'.", log: logFileSystem, type: .error, unzipPath)
            return
    }
    var subDirName: String = ""
    while let element = subDirEnumerator.nextObject() as? String {
        subDirName = element
        break
    }

    // Copy its content to the user's Workspace directory.
    guard let enumerator: FileManager.DirectoryEnumerator =
        fileManager.enumerator(atPath: unzipPath + subDirName + "/") else {
            os_log("Directory not found at '%@'.", log: logFileSystem, type: .error, unzipPath)
            return
    }
    while let element = enumerator.nextObject() as? String {
        var srcURL: URL = URL(fileURLWithPath: unzipPath + subDirName + "/")
        srcURL.appendPathComponent(element)
        var dstURL: URL = URL(fileURLWithPath: workspacePath)
        dstURL.appendPathComponent(element)
        
        // Create directories.
        if isDir(path: srcURL.path) {
            if !isDir(path: dstURL.path) {
                makeDirs(path: dstURL.path)
            }
        }
        
        // Copy files (after removing their previous version).
        if isFile(path: srcURL.path){
            if isFile(path: srcURL.path){
                do {
                    try fileManager.removeItem(at: dstURL)
                } catch let error {
                    os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
                }
            }
            do {
                try fileManager.copyItem(at: srcURL, to: dstURL)
            } catch let error {
                os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
            }
        }
    }
    
    // Clean up.
    do {
        try fileManager.removeItem(atPath: zipPath)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
    do {
        try fileManager.removeItem(atPath: unzipPath)
    } catch let error {
        os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
    }
}


extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: TimeZone.current.identifier)
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter
    }()
    static let iso8601like: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: TimeZone.current.identifier)
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: TimeZone.current.identifier)
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    static let readableDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: TimeZone.current.identifier)
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}


extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
    var iso8601like: String {
        return Formatter.iso8601like.string(from: self)
    }
    var readable: String {
        return Formatter.readable.string(from: self)
    }
    var readableDate: String {
        return Formatter.readableDate.string(from: self)
    }
}

enum JsonError: Error {
    case misformed
}
