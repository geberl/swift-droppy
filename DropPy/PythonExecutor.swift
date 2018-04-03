//
//  pythonExecutor.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON
import os.log


class PythonExecutor: NSObject {

    var tempDirPath: String
    var workflowFile: String
    var workspacePath: String
    var executablePath: String
    var executableArgs: String
    
    var startTime: DispatchTime
    
    var cacheDirPath: String
    var runnerFilePath: String
    var timestampDirPath: String
    var logFilePath: String

    var workflowPath: String
    
    var executionCancel: Bool
    var overallExitCode: Int

    init(tempDirPath: String, workflowFile: String, workspacePath: String, executablePath: String, executableArgs: String) {
        
        os_log("Executing workflow '%@'.", log: logExecution, type: .debug, workflowFile)
        
        self.tempDirPath = tempDirPath
        self.workflowFile = workflowFile
        self.workspacePath = workspacePath
        self.executablePath = executablePath
        self.executableArgs = executableArgs
        
        self.startTime = DispatchTime.now()
        
        self.cacheDirPath = tempDirPath + "_cache" + "/"
        self.runnerFilePath = tempDirPath + "run.py"
        self.timestampDirPath = tempDirPath + Date().iso8601like + "/"
        self.logFilePath = self.timestampDirPath + "droppy.log"
        
        self.workflowPath = workspacePath + "Workflows" + "/" + workflowFile
        
        self.executionCancel = false
        self.overallExitCode = 0

        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PythonExecutor.cancelExecution),
                                               name: .executionCancel, object: nil)
    }
    
    @objc func cancelExecution(_ notification: Notification) {
        self.executionCancel = true
    }
    
    func prepareNextTempDir(taskNumber: Int) -> String {
        let outputPath: String = self.timestampDirPath + String(taskNumber)
        if !isDir(path: outputPath) {
            makeDirs(path: outputPath)
        }
        return outputPath
    }

    func writeLog(prefix: String, lines: [String]) {
        // File is sure to exist at that point, may have content or be empty.
        var prefixedLine: String
        if let fileHandle = FileHandle(forWritingAtPath: self.logFilePath) {
            defer {
                fileHandle.closeFile()
            }
            for (n, line) in lines.enumerated() {
                if n == 0 {
                    prefixedLine = prefix + line + "\n"
                } else {
                    prefixedLine = String(repeating: " ", count: prefix.count) + line + "\n"
                }
                
                if let lineData = prefixedLine.data(using: String.Encoding.utf8) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(lineData)
                }
            }
        }
    }

    func writeWorkflowInputLog() {
        self.writeLog(prefix: "Workflow Date/Time:       ", lines: [Date().readable])
        self.writeLog(prefix: "Workspace Dir:            ", lines: [self.workspacePath])
        self.writeLog(prefix: "Workflow File:            ", lines: [self.workflowPath])
        self.writeLog(prefix: "Temp Dir:                 ", lines: [self.tempDirPath])
        self.writeLog(prefix: "Runner File:              ", lines: [self.runnerFilePath])
        self.writeLog(prefix: "Interpreter Executable:   ", lines: [self.executablePath])
        self.writeLog(prefix: "Interpreter Arguments:    ", lines: [self.executableArgs])
        self.writeLog(prefix: "", lines: [String(repeating: "=", count: 120)])
    }

    func writeWorkflowOutputLog () {
        self.writeLog(prefix: "", lines: [String(repeating: "=", count: 120)])
        
        if self.executionCancel {
            self.writeLog(prefix: "Result:                   ", lines: ["Cancelled by user"])
        } else {
            if self.overallExitCode > 0 {
                self.writeLog(prefix: "Result:                   ", lines: ["Error occurred, running Tasks aborted"])
            } else {
                self.writeLog(prefix: "Result:                   ", lines: ["Success"])
            }
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - self.startTime.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        self.writeLog(prefix: "Workflow Run Time:        ", lines: [String(format: "%.2f", timeInterval) + "s"])
    }

    func writeTaskInputLog(queueItem: JSON, queueCount: Int, taskNumber: Int, inputPath: String, outputPath: String) {

        let queueDict: Dictionary<String, SwiftyJSON.JSON> = queueItem.dictionaryValue
        guard let taskName: String = queueDict["task"]?.stringValue else { return }

        let logText: String = "Running Task \(taskNumber + 1)/\(queueCount): '\(taskName)'"
        self.writeLog(prefix: "", lines: [logText])
        os_log("%@", log: logExecution, type: .info, logText)

        if let queueItemParams: String = queueDict["kwargs"]?.rawString() {
            var queueItemParamsList = queueItemParams.components(separatedBy: .whitespacesAndNewlines)
            queueItemParamsList = queueItemParamsList.filter { !$0.isEmpty }
            let queueItemParamsOneLine = queueItemParamsList.joined(separator: " ")

            self.writeLog(prefix: "  Kwargs:                 ", lines: [queueItemParamsOneLine])
        } else {
            self.writeLog(prefix: "  Kwargs:                 ", lines: ["(none)"])
        }

        self.writeLog(prefix: "  Input Dir:              ", lines: [inputPath])
        self.writeLog(prefix: "  Output Dir:             ", lines: [outputPath])

        self.sendTaskStatusNotification(taskNumber: taskNumber, taskName: taskName, queueCount: queueCount)
    }

    func writeTaskOutputLog(out: [String], err: [String], exit: Int32) {
        self.writeLog(prefix: "  StdOut:                 ", lines: out)
        self.writeLog(prefix: "  StdErr:                 ", lines: err)
        self.writeLog(prefix: "  Exit Code:              ", lines: ["\(exit)"])

        let logText = " Exit Code: \(exit)"
        if exit > 0 {
            os_log("%@", log: logExecution, type: .error, logText)
        } else {
            os_log("%@", log: logExecution, type: .info, logText)
        }
    }

    func sendTaskStatusNotification(taskNumber: Int, taskName: String, queueCount: Int) {
        let statusText = "Task " + String(taskNumber + 1) + "/" + String(queueCount) + "\n" + taskName
        let statusDict:[String: String] = ["text": statusText]
        NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
    }

    func run() {
        // Make sure there is a file 'run.py' at the expected location.
        extractBundledRun()

        // Copy _cache dir from drop to timestampdir for execution.
        copyDir(sourceDirPath: self.cacheDirPath, targetDirPath: self.timestampDirPath)

        // Setup the log file.
        self.writeWorkflowInputLog()

        // Set dir "0".
        var inputPath = self.timestampDirPath + "0"

        // Prepare dir "1".
        var outputPath = self.prepareNextTempDir(taskNumber: 1)

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath), options: .alwaysMapped)
            let jsonObj = try JSON(data: data)
            if jsonObj != JSON.null {

                let queue: Array = jsonObj["queue"].arrayValue
                let queueCount = queue.count
                for (taskNumber, queueItem) in queue.enumerated() {
                    // Check if user clicked cancel in the meantime, abort before beginning work on the next Task.
                    if self.executionCancel {
                        break
                    }

                    self.writeTaskInputLog(queueItem: queueItem,
                                           queueCount: queueCount,
                                           taskNumber: taskNumber,
                                           inputPath: inputPath,
                                           outputPath: outputPath)

                    let (out, err, exit) = executeCommand(command: self.executablePath,
                                                          args: [self.executableArgs,
                                                                 self.runnerFilePath,
                                                                 "-w" + self.workspacePath,
                                                                 "-j" + self.workflowFile,
                                                                 "-i" + inputPath,
                                                                 "-o" + outputPath])

                    self.writeTaskOutputLog(out: out, err: err, exit: exit)

                    if exit > 0 {
                        self.overallExitCode = 1
                        break
                    }

                    if (taskNumber + 1 < queueCount) && !self.executionCancel {
                        // taskNumber +1 because taskNumber starts counting at 0 BUT queueCount at 1.

                        // Current Task's output directory is next Task's input directory.
                        inputPath = outputPath

                        // +2 because taskNumber starts counting at 0 AND we're preparing for the following Task.
                        outputPath = self.prepareNextTempDir(taskNumber: taskNumber + 2)

                        self.writeLog(prefix: "", lines: [String(repeating: "-", count: 120)])
                    }
                }
            }
        } catch let error {
            os_log("%@", log: logExecution, type: .error, error.localizedDescription)
        }
    }
    
    func cleanUp() {
        let statusDict:[String: String] = ["text": "Cleaning up\nPlease wait a moment"]
        NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
        
        let userDefaults = UserDefaults.standard
        let devModeEnabled: Bool = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        if !devModeEnabled && self.overallExitCode == 0 {
            removeDir(path: self.tempDirPath)
            makeDirs(path: self.tempDirPath)
        }
    }
    
    func evaluate() -> (String, Int) {
        self.writeWorkflowOutputLog()
        self.cleanUp()
        return (self.timestampDirPath, self.overallExitCode)
    }
}
