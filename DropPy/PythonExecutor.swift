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
            let stringFromDate = Date().iso8601
            tempPath = workspacePath + "/" + "Temp/" + stringFromDate + "/"
            if !isDir(path: tempPath) {
                makeDirs(path: tempPath)
            }
        }
        log.debug(tempPath)

        for (index, filePath) in self.filePaths.enumerated() {
            let statusDict:[String: String] = ["taskCurrent": "1",
                                               "taskTotal": "1",
                                               "fileCurrent": String(index + 1),
                                               "fileTotal": String(self.filePaths.count)]
            NotificationCenter.default.post(name: Notification.Name("executionStatus"),
                                            object: nil,
                                            userInfo: statusDict)
            
            let (output, error, status) = executeCommand(command: "/bin/sleep", args: ["10"])
            log.debug("o \(output)")
            log.debug("e \(error)")
            log.debug("s \(status)")
        }

        log.debug("pythonExecutor run finished")
    }
}
