//
//  pythonExecutor.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class PythonExecutor: NSObject {
    
    override init() {
        log.debug("pythonExecutor init started")
        
        // Todo next
        // check for existance of command executable (without parameters) right before, app crashes hard otherwise
        // probably best to check in the function itself and not here, and return an error code and message accordingly
        // maybe the bug that affects the "dead" interpreter I currently have in my config is also sorted then
        
        
        
        let (output, error, status) = executeCommand(command: "/bin/sleep", args: ["5"])
        log.debug("\(output)")
        log.debug("\(error)")
        log.debug("\(status)")
        
        log.debug("pythonExecutor init finished")
    }

}


func executeCommand(command: String, args: [String]) -> (output: [String], error: [String], exitCode: Int32) {
    // TODO probably not ok with the app sandbox.
    // Source: https://stackoverflow.com/questions/29514738/get-terminal-output-after-a-command-swift#29519615
    
    var output : [String] = []
    var error : [String] = []
    
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
    let status = task.terminationStatus
    
    return (output, error, status)
}
