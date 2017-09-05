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
        // Since the app stays responsive the user could change the settings during execution.

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
    
    func copyDroppedFiles(inputPath: String) {
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
    }

    func run() {
        guard let workspacePath = self.userDefaultWorkspacePath else { return }
        guard let workflowFile = self.workflowFile else { return }
        guard let interpreterInfo: Dictionary<String, String> = self.userDefaultInterpreters[Workflows.activeInterpreterName] else { return }
        
        let workflowPath = workspacePath + "/" + "Workflows" + "/" + workflowFile
        let executablePath: String = interpreterInfo["executable"]!
        let executableArgs: String = interpreterInfo["arguments"]!

        var (tempPath, inputPath, outputPath, runPath) = self.prepareTempDir(workspacePath: workspacePath)

        self.copyDroppedFiles(inputPath: inputPath)
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: workflowPath), options: .alwaysMapped)
            let jsonObj = JSON(data: data)
            if jsonObj != JSON.null {
                let queue: Array = jsonObj["queue"].arrayValue
                let queueCount = queue.count
                for (taskNumber, queueItem) in queue.enumerated() {

                    let queueDict: Dictionary<String, SwiftyJSON.JSON> = queueItem.dictionaryValue
                    guard let queueItemName: String = queueDict["task"]?.stringValue else { return }

                    log.info("--------------------------------------------")
                    log.info("Executing Task \(taskNumber + 1)/\(queueCount): '\(queueItemName)'")

                    if let queueItemParams: Dictionary<String, SwiftyJSON.JSON> = queueDict["kwargs"]?.dictionaryValue {
                        log.info(" Parameters:   \(queueItemParams)")
                    } else {
                        log.info(" Parameters:   (none)")
                    }

                    log.info(" Input Files:  \(inputPath)")
                    log.info(" Output Files: \(outputPath)")

                    let statusDict:[String: String] = ["taskCurrent": String(taskNumber),
                                                       "taskTotal": String(queueCount)]

                    NotificationCenter.default.post(name: Notification.Name("executionStatus"),
                                                    object: nil,
                                                    userInfo: statusDict)

                    let (out, err, exit) = executeCommand(command: executablePath,
                                                          args: [executableArgs,
                                                                 runPath,
                                                                 "-w" + workspacePath,
                                                                 "-j" + workflowFile,
                                                                 "-i" + inputPath,
                                                                 "-o" + outputPath])

                    log.info(" StdOut:       \(out)")
                    if err.count > 0 {
                        log.error(" StdErr:       \(err)")
                    } else {
                        log.info(" StdErr:       \(err)")
                    }
                    if exit > 0 {
                        log.error(" Exit Code:     \(exit)")
                    } else {
                        log.info(" Exit Code:     \(exit)")
                    }
                    
                    // Check if a fatal error occurred.
                    if exit > 0 {
                        log.info("--------------------------------------------")
                        log.error("Executing Tasks aborted")
                        break
                    }

                    // Prepare folders for next iteration.
                    if taskNumber + 1 < queueCount {
                        inputPath = outputPath
                        outputPath = self.prepareNextTempDir(tempPath: tempPath, taskNumber: taskNumber + 2)
                    }
                }
            }
        } catch let error {
            log.error(error.localizedDescription)
        }
    }
}
