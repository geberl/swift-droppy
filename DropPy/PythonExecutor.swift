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
                for (taskNumber, queueItem) in queue.enumerated() {
                    
                    log.debug("\(taskNumber)")
                    //log.debug(queueItem["name"])
                    log.debug(inputPath)
                    log.debug(outputPath)
                    
                    let statusDict:[String: String] = ["taskCurrent": String(taskNumber),
                                                       "taskTotal": String(queue.count)]

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
                    
                    log.debug("o \(out)")
                    log.debug("e \(err)")
                    log.debug("s \(exit)")
                    
                    // Prepare folders for next iteration.
                    if taskNumber + 1 < queue.count {
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
