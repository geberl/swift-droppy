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
        // Since the app stays responsive during execution the user could change the settings while performing Tasks.

        userDefaultDevModeEnabled = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        userDefaultWorkspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)
        userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
    }
    
    func prepareTempDir(workspacePath: String) -> (tempPath: String, inputPath: String, outputPath: String, runPath: String) {

        // Determine which directory to use as the temp dir.
        var tempPath: String = NSTemporaryDirectory()
        if self.userDefaultDevModeEnabled {
            let stringFromDate = Date().iso8601
            tempPath = workspacePath + "/" + "Temp/" + stringFromDate + "/"
        }
        
        // Setup the directory structure here.
        let inputPath: String = tempPath + "0"
        let outputPath: String = tempPath + "1"
        if !isDir(path: inputPath) {
            makeDirs(path: inputPath)
        }
        if !isDir(path: outputPath) {
            makeDirs(path: outputPath)
        }
        
        // Copy run.py from assets to the temp directory.
        let runPath: String = tempPath + "run.py"
        if let asset = NSDataAsset(name: "run", bundle: Bundle.main) {
            do {
                try asset.data.write(to: URL(fileURLWithPath: runPath))
            } catch {
                log.error("Unable to output run.py from assets")
            }
        }

        return (tempPath, inputPath, outputPath, runPath)
    }
    
    func prepareNextTempDir(tempPath: String, taskNumber: Int) -> String {
        
        let outputPath: String = tempPath + String(taskNumber)
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
        // TODO
    }

    func taskLog(tempPath: String, text: String) {
        // Write task.log to temp path.

        let taskLogPath = tempPath + "/" + "task.log"
        let textNl = text + "\n"

        do {
            if let fileHandle = FileHandle(forWritingAtPath: taskLogPath) {
                defer {
                    fileHandle.closeFile()
                }
                if let textData = textNl.data(using: String.Encoding.utf8) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(textData)
                }
            }
            else {
                try textNl.write(to: URL(fileURLWithPath: taskLogPath),
                                 atomically: false,
                                 encoding: String.Encoding.utf8)
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }

    func writeInputLog(tempPath: String, queueItem: JSON, queueCount: Int,
                       taskNumber: Int, inputPath: String, outputPath: String) {

        let queueDict: Dictionary<String, SwiftyJSON.JSON> = queueItem.dictionaryValue
        guard let queueItemName: String = queueDict["task"]?.stringValue else { return }

        var logText: String = "------------------------------------"
        self.taskLog(tempPath: tempPath,text: logText)
        log.info(logText)
        
        logText = "Executing Task \(taskNumber + 1)/\(queueCount): '\(queueItemName)'"
        self.taskLog(tempPath: tempPath,text: logText)
        log.info(logText)
        
        if let queueItemParams: Dictionary<String, SwiftyJSON.JSON> = queueDict["kwargs"]?.dictionaryValue {
            logText = " Parameters:   \(queueItemParams)"
            self.taskLog(tempPath: tempPath, text: logText)
            log.info(logText)
        } else {
            logText = " Parameters:   (none)"
            self.taskLog(tempPath: tempPath, text: logText)
            log.info(logText)
        }
        
        logText = " Input Files:  \(inputPath)"
        self.taskLog(tempPath: tempPath, text: logText)
        log.info(logText)
        
        logText = " Output Files: \(outputPath)"
        self.taskLog(tempPath: tempPath, text: logText)
        log.info(logText)
        
    }

    func writeOutputLog(tempPath: String, out: [String], err: [String],
                        exit: Int32) {

        var logText = " StdOut:       \(out)"
        self.taskLog(tempPath: tempPath, text: logText)
        log.info(logText)

        if err.count > 0 {
            logText = " StdErr:       \(err)"
            self.taskLog(tempPath: tempPath,text: logText)
            log.error(logText)
        } else {
            logText = " StdErr:       \(err)"
            self.taskLog(tempPath: tempPath,text: logText)
            log.info(logText)
        }

        if exit > 0 {
            logText = " Exit Code:     \(exit)"
            self.taskLog(tempPath: tempPath,text: logText)
            log.error(logText)
        } else {
            logText = " Exit Code:     \(exit)"
            self.taskLog(tempPath: tempPath,text: logText)
            log.info(logText)
        }

        if exit > 0 {
            logText = "------------------------------------"
            self.taskLog(tempPath: tempPath,text: logText)
            log.info(logText)
        
            logText = "Executing Tasks aborted"
            self.taskLog(tempPath: tempPath,text: logText)
            log.error(logText)
        }
    }
    
    func sendNotification(taskNumber: Int, queueCount: Int) {
        
        let statusDict:[String: String] = ["taskCurrent": String(taskNumber),
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

        var (tempPath, inputPath, outputPath, runPath) = self.prepareTempDir(workspacePath: workspacePath)

        self.handleDroppedFiles(inputPath: inputPath)

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath),
                                options: .alwaysMapped)
            let jsonObj = JSON(data: data)
            if jsonObj != JSON.null {
                
                let queue: Array = jsonObj["queue"].arrayValue
                let queueCount = queue.count
                for (taskNumber, queueItem) in queue.enumerated() {

                    self.writeInputLog(tempPath: tempPath,
                                       queueItem: queueItem,
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

                    self.writeOutputLog(tempPath: tempPath,
                                        out: out,
                                        err: err,
                                        exit: exit)

                    if exit > 0 {
                        break
                    }

                    if taskNumber < queueCount {
                        inputPath = outputPath
                        outputPath = self.prepareNextTempDir(tempPath: tempPath,
                                                             taskNumber: taskNumber + 2)
                    }
                }
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
}
