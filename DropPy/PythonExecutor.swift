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

    var startTime = DispatchTime.now()
    let startDateTime = Date()
    var devModeEnabled: Bool = false
    var workspacePath: String
    var workflowFile: String
    var workflowPath: String
    var executablePath: String
    var executableArgs: String
    var tempPath: String
    var runnerPath: String
    var filesJsonPath: String
    var logFilePath: String
    var filePaths: [String]
    var overallExitCode: Int

    init(workflowFile: String, filePaths: [String]) {
        // It's only save to store the settings as they were on drop and access them from here.
        // Since the app stays responsive during execution the user could change the settings while performing Tasks.
        let userDefaults = UserDefaults.standard

        self.devModeEnabled = userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled)
        self.workspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/"
        self.workflowFile = workflowFile
        self.workflowPath = workspacePath + "Workflows" + "/" + workflowFile

        let userDefaultInterpreters = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        let interpreterInfo: Dictionary<String, String> = userDefaultInterpreters[Workflows.activeInterpreterName]!
        self.executablePath = interpreterInfo["executable"]!
        self.executableArgs = interpreterInfo["arguments"]!

        if self.devModeEnabled {
            self.tempPath = self.workspacePath + "Temp" + "/" + self.startDateTime.iso8601 + "/"
        } else {
            self.tempPath = NSTemporaryDirectory() + "DropPy" + "/" + self.startDateTime.iso8601 + "/"
        }

        self.runnerPath = tempPath + "run.py"
        self.filesJsonPath = tempPath + "files.json"
        self.logFilePath = tempPath + "task.log"
        self.filePaths = filePaths
        self.overallExitCode = 0

        super.init()
    }

    func prepareFirstTempDir() -> (inputPath: String, outputPath: String) {
        // Setup the directory structure here.
        let inputPath = self.prepareNextTempDir(taskNumber: 0)
        let outputPath = self.prepareNextTempDir(taskNumber: 1)

        // Copy run.py from assets to the temp directory.
        if let asset = NSDataAsset(name: "run", bundle: Bundle.main) {
            do {
                try asset.data.write(to: URL(fileURLWithPath: self.runnerPath))
            } catch {
                log.error("Unable to copy run.py from assets")
            }
        }

        // Setup the log file.
        self.writeWorkflowInputLog()

        return (inputPath, outputPath)
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
        do {
            let jsonObject: JSON = ["files": self.filePaths]
            let jsonString = jsonObject.description
            try jsonString.write(to: URL(fileURLWithPath: self.filesJsonPath),
                                 atomically: false,
                                 encoding: String.Encoding.utf8)
        } catch {
            log.error(error.localizedDescription)
        }
    }

    func taskLog(prefix: String, lines: [String]) {
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
                    prefixedLine = String(repeating: " ", count: prefix.characters.count) + line + "\n"
                }
                
                if let lineData = prefixedLine.data(using: String.Encoding.utf8) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(lineData)
                }
            }
        }
    }

    func writeWorkflowInputLog() {
        // Create an empty file at logFilePath.
        do {
            try "".write(to: URL(fileURLWithPath: self.logFilePath),
                         atomically: false,
                         encoding: String.Encoding.utf8)
        } catch let error {
            log.error(error.localizedDescription)
            return
        }

        self.taskLog(prefix: "", lines: ["Start Date & Time: \(self.startDateTime.readable)"])
        self.taskLog(prefix: "", lines: ["Dev Mode Enabled:  \(self.devModeEnabled)"])
        self.taskLog(prefix: "", lines: ["Workspace Path:    " + self.workspacePath])
        self.taskLog(prefix: "", lines: ["Workflow Path:     " + self.workflowPath])
        self.taskLog(prefix: "", lines: ["Interpreter Path:  " + self.executablePath])
        self.taskLog(prefix: "", lines: ["Interpreter Args:  " + self.executableArgs])
        self.taskLog(prefix: "", lines: ["Temp Path:         " + self.tempPath])
        self.taskLog(prefix: "", lines: ["Runner Path:       " + self.runnerPath])
        self.taskLog(prefix: "", lines: ["Files Json Path:   " + self.filesJsonPath])
        self.taskLog(prefix: "", lines: ["Logfile Path:      " + self.logFilePath])
        self.taskLog(prefix: "", lines: [String(repeating: "=", count: 80)])
    }

    func writeWorkflowOutputLog () {
        self.taskLog(prefix: "", lines: [String(repeating: "=", count: 80)])

        if self.overallExitCode > 0 {
            self.taskLog(prefix: "", lines: ["Result:           Error occurred, running Tasks aborted"])
        } else {
            self.taskLog(prefix: "", lines: ["Result:           Success"])
        }

        let endTime = DispatchTime.now()
        let nanoTime = endTime.uptimeNanoseconds - self.startTime.uptimeNanoseconds
        let timeInterval = Double(nanoTime) / 1_000_000_000
        self.taskLog(prefix: "", lines: ["Run time:         " + String(format: "%.2f", timeInterval) + "s"])
    }

    func writeTaskInputLog(queueItem: JSON, queueCount: Int, taskNumber: Int,
                           inputPath: String, outputPath: String) {

        let queueDict: Dictionary<String, SwiftyJSON.JSON> = queueItem.dictionaryValue
        guard let taskName: String = queueDict["task"]?.stringValue else { return }

        let logText: String = "Running Task \(taskNumber + 1)/\(queueCount): '\(taskName)'"
        self.taskLog(prefix: "", lines: [logText])
        log.info(logText)

        if let queueItemParams: Dictionary<String, SwiftyJSON.JSON> = queueDict["kwargs"]?.dictionaryValue {
            self.taskLog(prefix: "  Parameters:     ", lines: ["\(queueItemParams)"])
        } else {
            self.taskLog(prefix: "  Parameters:     ", lines: ["(none)"])
        }

        self.taskLog(prefix: "  Input Path:     ", lines: [inputPath])
        self.taskLog(prefix: "  Output Path:    ", lines: [outputPath])
        
        self.sendStatusNotification(taskNumber: taskNumber,
                                    taskName: taskName,
                                    queueCount: queueCount)
    }

    func writeTaskOutputLog(out: [String], err: [String], exit: Int32) {
        self.taskLog(prefix: "  StdOut:         ", lines: out)
        self.taskLog(prefix: "  StdErr:         ", lines: err)
        self.taskLog(prefix: "  Exit Code:      ", lines: ["\(exit)"])

        let logText = " Exit Code:   \(exit)"
        if exit > 0 {
            log.error(logText)
        } else {
            log.info(logText)
        }
    }

    func sendStatusNotification(taskNumber: Int, taskName: String, queueCount: Int) {
        
        let statusDict:[String: String] = ["taskCurrent": String(taskNumber + 1),
                                           "taskTotal": String(queueCount),
                                           "taskName": taskName]
        
        NotificationCenter.default.post(name: Notification.Name("executionStatus"),
                                        object: nil,
                                        userInfo: statusDict)
    }

    func run() {
        var (inputPath, outputPath) = self.prepareFirstTempDir()
        self.handleDroppedFiles(inputPath: inputPath)

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath),
                                options: .alwaysMapped)
            let jsonObj = JSON(data: data)
            if jsonObj != JSON.null {

                let queue: Array = jsonObj["queue"].arrayValue
                let queueCount = queue.count
                for (taskNumber, queueItem) in queue.enumerated() {

                    self.writeTaskInputLog(queueItem: queueItem,
                                           queueCount: queueCount,
                                           taskNumber: taskNumber,
                                           inputPath: inputPath,
                                           outputPath: outputPath)

                    let (out, err, exit) = executeCommand(command: self.executablePath,
                                                          args: [self.executableArgs,
                                                                 self.runnerPath,
                                                                 "-w" + self.workspacePath,
                                                                 "-j" + self.workflowFile,
                                                                 "-i" + inputPath,
                                                                 "-o" + outputPath])

                    self.writeTaskOutputLog(out: out,
                                            err: err,
                                            exit: exit)

                    if exit > 0 {
                        self.overallExitCode = 1
                        // TODO only break THIS and parent queues, sister-queues might be unaffected by this failed Task
                        break
                    }

                    if taskNumber < queueCount {
                        inputPath = outputPath
                        outputPath = self.prepareNextTempDir(taskNumber: taskNumber + 2)
                        self.taskLog(prefix: "", lines: [String(repeating: "-", count: 80)])
                    }
                }
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }

    func cleanUp() {
        if !self.devModeEnabled && self.overallExitCode == 0 {
            let fileManager = FileManager.default

            guard let enumerator: FileManager.DirectoryEnumerator =
                fileManager.enumerator(atPath: self.tempPath) else {
                    print("Temp directory not found: \(self.tempPath)")
                    return
            }

            while let element = enumerator.nextObject() as? String {
                let elementPath = "\(self.tempPath)\(element)"
                if element != "task.log" {
                    do {
                        try fileManager.removeItem(atPath: elementPath)
                    } catch let error {
                        log.error(error.localizedDescription)
                    }
                }
            }

            log.debug("Removed intermediary files from \(self.tempPath)")
        }
    }

    func evaluate() -> (String, String, String) {
        self.writeWorkflowOutputLog()
        self.cleanUp()
        return (self.logFilePath, self.tempPath, "\(self.overallExitCode)")
    }
}
