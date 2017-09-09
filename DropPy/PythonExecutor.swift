//
//  pythonExecutor.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON


class PythonExecutor: NSObject {

    var workflowFile: String?
    var filePaths: [String]
    var tempPath: String
    var logFilePath: String
    var overallExitCode: Int

    init(workflowFile: String, filePaths: [String]) {
        self.workflowFile = workflowFile
        self.filePaths = filePaths
        self.tempPath = ""
        self.logFilePath = ""
        self.overallExitCode = 0
        super.init()
        self.loadSettings()
    }

    let userDefaults = UserDefaults.standard
    var userDefaultDevModeEnabled: Bool = false
    var userDefaultWorkspacePath: String? = nil
    var userDefaultInterpreters: Dictionary<String, Dictionary<String, String>> = [:]

    func loadSettings() {
        // It's only save to store the settings as they were on drop and access them from here.
        // Since the app stays responsive during execution the user could change the settings while performing Tasks.
        userDefaultDevModeEnabled = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        userDefaultWorkspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)
        userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
    }

    func prepareTempDir(workspacePath: String) -> (inputPath: String, outputPath: String, runPath: String) {
        // Determine which directory to use as the temp dir.
        if self.userDefaultDevModeEnabled {
            let stringFromDate = Date().iso8601
            self.tempPath = workspacePath + "/" + "Temp/" + stringFromDate + "/"
        } else {
            self.tempPath = NSTemporaryDirectory()
        }

        // Setup the log file.
        self.logFilePath = self.tempPath + "task.log"

        // Setup the directory structure here.
        let inputPath: String = self.tempPath + "0"
        let outputPath: String = self.tempPath + "1"
        if !isDir(path: inputPath) {
            makeDirs(path: inputPath)
        }
        if !isDir(path: outputPath) {
            makeDirs(path: outputPath)
        }

        // Copy run.py from assets to the temp directory.
        let runPath: String = self.tempPath + "run.py"
        if let asset = NSDataAsset(name: "run", bundle: Bundle.main) {
            do {
                try asset.data.write(to: URL(fileURLWithPath: runPath))
            } catch {
                log.error("Unable to output run.py from assets")
            }
        }

        return (inputPath, outputPath, runPath)
    }

    func prepareNextTempDir(taskNumber: Int) -> String {
        let outputPath: String = self.tempPath + String(taskNumber)
        if !isDir(path: outputPath) {
            makeDirs(path: outputPath)
        }
        return outputPath
    }
    
    func handleDroppedFiles(inputPath: String) {
        // Copy the originally dropped files to the "0" directory.
        let fileManager = FileManager.default
        for srcPath in self.filePaths {

            let srcURL: URL = URL(fileURLWithPath: srcPath)

            var dstURL: URL = URL(fileURLWithPath: inputPath)
            dstURL.appendPathComponent(srcURL.lastPathComponent)

            do {
                try fileManager.copyItem(at: srcURL, to: dstURL)
            } catch {
                log.error("Unable to copy file '\(srcPath)'.")
            }
        }

        // Write files.json to temp path.
        let filesJsonPath = URL(fileURLWithPath: self.tempPath + "/" + "files.json")
        do {
            let jsonObject: JSON = ["files": self.filePaths]
            let jsonString = jsonObject.description
            try jsonString.write(to: filesJsonPath,
                                 atomically: false,
                                 encoding: String.Encoding.utf8)
        } catch {
            log.error(error.localizedDescription)
        }
    }

    func taskLog(prefix: String, lines: [String]) {
        var prefixedLine: String
        do {
            if let fileHandle = FileHandle(forWritingAtPath: self.logFilePath) {
                defer {
                    fileHandle.closeFile()
                }
                for (n, line) in lines.enumerated() {
                    if n == 0 {
                        prefixedLine = prefix + line + "\n"
                    } else {
                        prefixedLine = String(repeating: " ", count: prefix.characters.count) + line + "\n"
                    }

                    if let lineData = prefixedLine.data(using: String.Encoding.utf8) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(lineData)
                    }
                }
            }
            else {
                for (n, line) in lines.enumerated() {
                    if n == 0 {
                        prefixedLine = prefix + line + "\n"
                    } else {
                        prefixedLine = String(repeating: " ", count: prefix.characters.count) + line + "\n"
                    }

                    try prefixedLine.write(to: URL(fileURLWithPath: self.logFilePath),
                                           atomically: false,
                                           encoding: String.Encoding.utf8)
                }
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }

    func writeInputLog(queueItem: JSON, queueCount: Int, taskNumber: Int,
                       inputPath: String, outputPath: String) {

        let queueDict: Dictionary<String, SwiftyJSON.JSON> = queueItem.dictionaryValue
        guard let queueItemName: String = queueDict["task"]?.stringValue else { return }

        self.taskLog(prefix: "", lines: [String(repeating: "-", count: 80)])

        let logText: String = "Executing Task \(taskNumber + 1)/\(queueCount): '\(queueItemName)'"
        self.taskLog(prefix: "", lines: [logText])
        log.info(logText)

        if let queueItemParams: Dictionary<String, SwiftyJSON.JSON> = queueDict["kwargs"]?.dictionaryValue {
            self.taskLog(prefix: "  Parameters:   ", lines: ["\(queueItemParams)"])
        } else {
            self.taskLog(prefix: "  Parameters:   ", lines: ["(none)"])
        }

        self.taskLog(prefix: "  Input Path:   ", lines: [inputPath])
        self.taskLog(prefix: "  Output Path:  ", lines: [outputPath])
    }

    func writeOutputLog(out: [String], err: [String], exit: Int32) {

        self.taskLog(prefix: "  StdOut:       ", lines: out)
        self.taskLog(prefix: "  StdErr:       ", lines: err)
        self.taskLog(prefix: "  Exit Code:    ", lines: ["\(exit)"])

        let logText = " Exit Code: \(exit)"
        if exit > 0 {
            log.error(logText)
            self.taskLog(prefix: "", lines: [String(repeating: "-", count: 80)])
            self.taskLog(prefix: "", lines: ["Executing Tasks aborted"])
        } else {
            log.info(logText)
        }
    }

    func sendNotification(taskNumber: Int, queueCount: Int) {
        
        let statusDict:[String: String] = ["taskCurrent": String(taskNumber + 1),
                                           "taskTotal": String(queueCount)]
        
        NotificationCenter.default.post(name: Notification.Name("executionStatus"),
                                        object: nil,
                                        userInfo: statusDict)
    }

    func run() {

        guard let workspacePath = self.userDefaultWorkspacePath else { return }
        guard let workflowFile = self.workflowFile else { return }
        guard let interpreterInfo: Dictionary<String, String> = self.userDefaultInterpreters[Workflows.activeInterpreterName] else { return }

        let workflowPath = workspacePath + "/" + "Workflows" + "/" + workflowFile
        let executablePath: String = interpreterInfo["executable"]!
        let executableArgs: String = interpreterInfo["arguments"]!

        var (inputPath, outputPath, runPath) = self.prepareTempDir(workspacePath: workspacePath)

        self.handleDroppedFiles(inputPath: inputPath)

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath),
                                options: .alwaysMapped)
            let jsonObj = JSON(data: data)
            if jsonObj != JSON.null {
                
                let queue: Array = jsonObj["queue"].arrayValue
                let queueCount = queue.count
                for (taskNumber, queueItem) in queue.enumerated() {

                    self.writeInputLog(queueItem: queueItem,
                                       queueCount: queueCount,
                                       taskNumber: taskNumber,
                                       inputPath: inputPath,
                                       outputPath: outputPath)
                    
                    self.sendNotification(taskNumber: taskNumber,
                                          queueCount: queueCount)

                    let (out, err, exit) = executeCommand(command: executablePath,
                                                          args: [executableArgs,
                                                                 runPath,
                                                                 "-w" + workspacePath,
                                                                 "-j" + workflowFile,
                                                                 "-i" + inputPath,
                                                                 "-o" + outputPath])

                    self.writeOutputLog(out: out,
                                        err: err,
                                        exit: exit)

                    if exit > 0 {
                        self.overallExitCode = 1
                        break
                    }

                    if taskNumber < queueCount {
                        inputPath = outputPath
                        outputPath = self.prepareNextTempDir(taskNumber: taskNumber + 2)
                    }
                }
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }

    func evaluate() -> (String, String, String) {
        return (self.logFilePath, self.tempPath, "\(self.overallExitCode)")
    }
}
