//
//  pythonExecutor.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class PythonExecutor: NSObject {

    let userDefaults = UserDefaults.standard

    var userDefaultDevModeEnabled: Bool = false
    var userDefaultWorkspacePath: String? = nil
    var userDefaultInterpreters: Dictionary<String, Dictionary<String, String>> = [:]

    var workflowFile: String?
    var filePaths: [String]

    init(workflowFile: String, filePaths: [String]) {
        self.workflowFile = workflowFile
        self.filePaths = filePaths
        super.init()
        self.loadSettings()
    }

    func loadSettings() {
        // It's only save to store the settings as they were on drop and access them from here.
        // Since the app stays responsive the user could change the settings during execution.

        userDefaultDevModeEnabled = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        userDefaultWorkspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)
        userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
    }

    func run() {
        log.debug("pythonExecutor run started")

        guard let workflowFile = self.workflowFile else { return }
        guard let workspacePath = self.userDefaultWorkspacePath else { return }

        let workflowPath = workspacePath + "/" + workflowFile
        log.debug(workflowPath)

        var tempPath: String = NSTemporaryDirectory()
        if self.userDefaultDevModeEnabled {
            tempPath = workspacePath + "/" + "Temp" + "/"
            if !isDir(path: tempPath) {
                makeDirs(path: tempPath)
            }
        }
        log.debug(tempPath)
        print(isDir(path: tempPath))

        for filePath in self.filePaths {
            log.debug(filePath)
        }

        let (output, error, status) = executeCommand(command: "/bin/sleep", args: ["2"])
        log.debug("o \(output)")
        log.debug("e \(error)")
        log.debug("s \(status)")

        log.debug("pythonExecutor run finished")
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
