//
//  ViewController.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {
    
    @IBOutlet weak var logoImage: NSImageCell!
    @IBOutlet weak var zoneImage: NSImageCell!

    override func viewWillAppear() {
        super.viewWillAppear()
    
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.setZoneLine(notification:)),
                                               name: Notification.Name("draggingEnteredOk"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.setZoneDashed(notification:)),
                                               name: Notification.Name("draggingExited"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewController.setZoneDashed(notification:)),
                                               name: Notification.Name("draggingEnded"), object: nil)
    }
    
    func setZoneDashed(notification: Notification) {
        zoneImage.image = NSImage(named: "ZoneDashed")
    }
    
    func setZoneLine(notification: Notification) {
        zoneImage.image = NSImage(named: "ZoneLine")
    }

    func executeCommand(command: String, args: [String]) -> String {
        let task = Process()
        task.launchPath = command
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        return output        
    }
    
    func runScriptJson(path: String) {
        // Run python script through interpreter
        // Passing -B to not get a __pycache__folder, the full path to executor.py and the full path to the json file
        // The final output of the command is empty, no point in printing it to the log, the piped messages already are printed
        
        //let commandOutput = executeCommand(command: "/bin/echo", args: ["Hello, I am here!"])
        //let commandOutput = executeCommand(command: "/bin/cp", args: [path, path + ".bak"])
        //log.debug("Command Outout: \(commandOutput)")
        
        let framework = "Python 3"

        if Settings.frameworks[framework] != nil {
            log.debug("Framework '\(framework)' found")

            let interpreter: String = Settings.frameworks[framework]!["interpreter"]!
            let interpreterArgs: String = Settings.frameworks[framework]!["interpreter args"]!
            
            let runner: String = Settings.frameworks[framework]!["runner"]!
            let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
            let runnerPath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)\(framework)/\(runner)")
            let strRunnerPath: String = runnerPath.path
            
            var runnerArgs: String = Settings.frameworks[framework]!["runner args"]!
            runnerArgs = runnerArgs.replacingOccurrences(of: "$(JSONFILE)", with: path)
            
            log.debug("  Interpreter: \(interpreter) \(interpreterArgs)")
            log.debug("  Runner: \(strRunnerPath) \(runnerArgs)")

            _ = executeCommand(command: interpreter, args: [interpreterArgs, strRunnerPath, runnerArgs])
        }
        else {
            log.error("Framework '\(framework)' not found in settings.json!")
        }
    }
}
