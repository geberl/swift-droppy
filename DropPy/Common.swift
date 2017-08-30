//
//  Common.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


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
    let filemgr = FileManager.default
    do {
        try filemgr.createDirectory(atPath: path,
                                    withIntermediateDirectories: true,
                                    attributes: nil)
    } catch let error as NSError {
        log.error(error.localizedDescription)
    }
}


func executeCommand(command: String, args: [String]) -> (output: [String], error: [String], exitCode: Int32) {
    // This is probably not ok with the app sandbox. Untested though.
    // Source: https://stackoverflow.com/questions/29514738/get-terminal-output-after-a-command-swift#29519615
    
    var output: [String] = []
    var error: [String] = []
    var status: Int32
    
    if isFile(path: command) {
        
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
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
        status = task.terminationStatus
        
    } else {
        error.append("Command not found")
        error.append(command)
        status = 1
    }
    
    return (output, error, status)
}


extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        return formatter
    }()
}


extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}
