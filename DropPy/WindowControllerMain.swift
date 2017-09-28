//
//  WindowControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 04.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON
import os.log


class WindowControllerMain: NSWindowController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var ToolbarDropdown: NSMenu!

    @IBOutlet weak var workflowPopUp: NSPopUpButton!

    @IBOutlet weak var actionButtons: NSSegmentedControl!
    
    @IBAction func ToolbarActions(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.editWorkflow()
        }
        else if sender.selectedSegment == 1 {
            self.openFinder()
        }
        else if sender.selectedSegment == 2 {
            self.addWorkflow()
        }
    }

    lazy var editorWindowController: WindowControllerEditor  = {
        let wcSB = NSStoryboard(name: "Editor", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerEditor
    }()

    override func windowWillLoad() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.refreshToolbarDropdown(notification:)),
                                               name: Notification.Name("workflowsChanged"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.disableToolbar(notification:)),
                                               name: Notification.Name("droppingOk"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.enableToolbar(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.evaluateWorkflowResults(notification:)),
                                               name: Notification.Name("executionFinished"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.updateErrorAlert(notification:)),
                                               name: Notification.Name("updateError"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.updateNotAvailableAlert(notification:)),
                                               name: Notification.Name("updateNotAvailable"),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.updateAvailableAlert(notification:)),
                                               name: Notification.Name("updateAvailable"),
                                               object: nil)
    }
    
    func disableToolbar(notification: Notification){
        for menuItem in ToolbarDropdown.items {
            menuItem.isEnabled = false
        }
        actionButtons.setEnabled(false, forSegment: 0)
        actionButtons.setEnabled(false, forSegment: 1)
        actionButtons.setEnabled(false, forSegment: 2)
    }
    
    func enableToolbar(notification: Notification){
        for menuItem in ToolbarDropdown.items {
            menuItem.isEnabled = true
        }
        actionButtons.setEnabled(true, forSegment: 0)
        actionButtons.setEnabled(true, forSegment: 1)
        actionButtons.setEnabled(true, forSegment: 2)
    }

    func refreshToolbarDropdown(notification: Notification){
        self.refreshToolbarDropdown()
    }

    func refreshToolbarDropdown() {
        // Start fresh with an empty dropdown.
        ToolbarDropdown.removeAllItems()

        // Sort Workflow names alphabetically.
        let allWorkflowNames: [String] = NSDictionary(dictionary: AppState.allWorkflows).allKeys as! [String]
        let sortedWorkflowNames = allWorkflowNames.sorted(){ $0 < $1 }

        // Add Workflows to the dropdown in that order.
        for name: String in sortedWorkflowNames {
            let newMenuItem = NSMenuItem()
            newMenuItem.title = name
            newMenuItem.target = self
            newMenuItem.action = #selector(workflowSelectionChanged)
            newMenuItem.isEnabled = true
            ToolbarDropdown.addItem(newMenuItem)
        }

        // Select the Workflow that was previously selected (or the first one if that failed).
        if let workflowSelected = userDefaults.string(forKey: UserDefaultStruct.workflowSelected) {
            if allWorkflowNames.contains(workflowSelected) {
                self.workflowPopUp.selectItem(withTitle: workflowSelected)
            } else {
                os_log("Unable to select Workflow '%@' (doesn't exist any more).", log: logUi, type: .info,
                       workflowSelected)
                AppState.activeName = nil
                AppState.activeInterpreterName = nil
                AppState.activeJsonFile = nil
                AppState.activeLogoFile = nil
            }
        } else {
            AppState.activeName = nil
            AppState.activeInterpreterName = nil
            AppState.activeJsonFile = nil
            AppState.activeLogoFile = nil
        }
        self.workflowSelectionChanged()
    }

    func workflowSelectionChanged() {
        if let workflowName: String = self.workflowPopUp.selectedItem?.title {
            userDefaults.set(workflowName, forKey: UserDefaultStruct.workflowSelected)
            AppState.activeName = workflowName
            AppState.activeJsonFile = AppState.allWorkflows[workflowName]?["file"]
            AppState.activeInterpreterName = AppState.allWorkflows[workflowName]?["interpreterName"]
            AppState.activeLogoFile = AppState.allWorkflows[workflowName]?["image"]
        } else {
            userDefaults.set(nil, forKey: UserDefaultStruct.workflowSelected)
            AppState.activeName = nil
            AppState.activeJsonFile = nil
            AppState.activeInterpreterName = nil
            AppState.activeLogoFile = nil
        }
        NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
    }

    func openFinder() {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        guard let jsonFile: String = AppState.activeJsonFile else { return }

        NSWorkspace.shared().selectFile(workspacePath + "Workflows" + "/" + jsonFile,
                                        inFileViewerRootedAtPath: workspacePath)
    }

    func editWorkflow() {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        guard let jsonFile: String = AppState.activeJsonFile else { return }
        
        let jsonPath: String = workspacePath + "Workflows" + "/" + jsonFile

        if let editorForWorkflows: String = self.userDefaults.string(forKey: UserDefaultStruct.editorForWorkflows) {
            
            if editorForWorkflows == "Internal Workflow editor" {
                // TODO: Implement internal Workflow editor and have it open from here.
                // Should currently not be possible to land here, deactivated, entry not displaed in preferences.
                os_log("TODO: Open internal Workflow editor now", log: logUi, type: .debug)

            } else if editorForWorkflows == "Internal text editor" {
                self.editorWindowController.showWindow(self)

                // Put path into dict inside Notification.
                let pathDict:[String: String] = ["path": jsonPath]
                NotificationCenter.default.post(name: Notification.Name("loadFileInEditor"), object: nil, userInfo: pathDict)

            } else if editorForWorkflows == "External text editor" {
                guard let editorAppPath: String = self.userDefaults.string(forKey: UserDefaultStruct.editorAppPath) else { return }
                if isDir(path: editorAppPath) {
                    // Passing custom parameters to the external editor is currently not possible.
                    NSWorkspace.shared().openFile(jsonPath, withApplication: editorAppPath)
                } else {
                    NotificationCenter.default.post(name: Notification.Name("editorNotFound"), object: nil)
                }
            }
        }
    }
    
    func addWorkflow() {
       guard let workspacePath = checkWorkspaceInfo() else { return }
        
       do {
            // Get the current datetime as a string
            let stringFromDate = Date().iso8601
        
            // Determine Workflow name (for inside the JSON file) and the JSON file's filename.
            let workflowName: String = "New Workflow \(stringFromDate)"
            let workflowFileName: String = "new_workflow_\(stringFromDate).json"
        
            // Create SwiftyJSON object
            let jsonObject: JSON = ["name": workflowName,
                                    "author": "Your name here",
                                    "description": "A short description what this Workflow does. Currently not accessed by DropPy. For now just for your own documentation purposes.",
                                    "image": "",
                                    "interpreterName": AppState.interpreterStockName,
                                    "queue": []]
        
            // Convert SwiftyJSON object to string.
            let jsonString = jsonObject.description
        
            // Setup objects needed for directory and file access.
            let filePath: URL = NSURL.fileURL(withPath: workspacePath + "Workflows" + "/" + workflowFileName)
        
            // Write json string to file, this overwrites a preexisting file here.
            try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)

            // Update global Workflow object.
            AppState.activeInterpreterName = AppState.interpreterStockName
            AppState.activeJsonFile = workflowFileName
            AppState.activeName = workflowName
            AppState.activeLogoFile = nil

            // Open new file in editor.
            self.editWorkflow()
        } catch {
            os_log("%@", log: logUi, type: .error, error.localizedDescription)
        }
    }

    func evaluateWorkflowResults(notification: Notification) {
        guard let logFilePath = notification.userInfo?["logFilePath"] as? String else { return }
        guard let tempPath = notification.userInfo?["tempPath"] as? String else { return }
        guard let dropExitCode = notification.userInfo?["dropExitCode"] as? String else { return }
        guard let execExitCode = notification.userInfo?["execExitCode"] as? String else { return }
        
        if (Int(dropExitCode)! > 0) || (Int(execExitCode)! > 0) {
            self.executionErrorAlert(logFilePath: logFilePath, tempPath: tempPath)
        }
    }

    func executionErrorAlert(logFilePath: String, tempPath: String) {
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "Running one of your Tasks failed"
        errorAlert.informativeText = "Take a look in the log file for details."
        errorAlert.addButton(withTitle: "Ok")
        errorAlert.addButton(withTitle: "Open temp dir")
        errorAlert.addButton(withTitle: "Open log file")
        errorAlert.layout()
        errorAlert.alertStyle = NSAlertStyle.warning
        errorAlert.icon = NSImage(named: "error")
        let response: NSModalResponse = errorAlert.runModal()

        if response == NSAlertFirstButtonReturn {
            // Do nothing when clicked ok.
        } else if response == NSAlertSecondButtonReturn {
            // Open temp dir in finder.
            NSWorkspace.shared().selectFile(logFilePath, inFileViewerRootedAtPath: tempPath)
        } else if response == NSAlertThirdButtonReturn {
            // Open log file in user editor.
            NSWorkspace.shared().openFile(logFilePath)
        }
    }

    func updateErrorAlert(notification: Notification) {
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "Unable to check for updates"
        errorAlert.informativeText = "Are you connected?"
        errorAlert.addButton(withTitle: "Visit Website")
        errorAlert.addButton(withTitle: "Cancel")
        errorAlert.layout()
        errorAlert.alertStyle = NSAlertStyle.warning
        errorAlert.icon = NSImage(named: "error")

        let response: NSModalResponse = errorAlert.runModal()

        if response == NSAlertFirstButtonReturn {
            guard let url = URL(string: "https://droppyapp.com/"), NSWorkspace.shared().open(url) else { return }
        }
    }

    func updateNotAvailableAlert(notification: Notification) {
        guard let releaseNotesLink = notification.userInfo?["releaseNotesLink"] as? String else { return }
        guard let thisVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "No update available"
        errorAlert.informativeText = "You're already using the latest version, v" + thisVersionString + "."
        errorAlert.addButton(withTitle: "Ok")
        errorAlert.addButton(withTitle: "Release Notes")
        errorAlert.layout()
        errorAlert.icon = NSImage(named: "AppIcon")
        
        let response: NSModalResponse = errorAlert.runModal()
        
        if response == NSAlertSecondButtonReturn {
            guard let url = URL(string: releaseNotesLink), NSWorkspace.shared().open(url) else { return }
        }
    }

    func updateAvailableAlert(notification: Notification) {
        guard let thisVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }
        guard let newVersionString = notification.userInfo?["versionString"] as? String else { return }
        guard let releaseNotesLink = notification.userInfo?["releaseNotesLink"] as? String else { return }
        guard let downloadLink = notification.userInfo?["downloadLink"] as? String else { return }

        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "New update available"
        errorAlert.informativeText = "There's a new version of DropPy, v" + newVersionString + ".\nYou're currently using v" + thisVersionString + "."
        errorAlert.addButton(withTitle: "Download")
        errorAlert.addButton(withTitle: "What's new?")
        errorAlert.addButton(withTitle: "Cancel")
        errorAlert.layout()
        errorAlert.icon = NSImage(named: "AppIcon")
        let response: NSModalResponse = errorAlert.runModal()

        if response == NSAlertFirstButtonReturn {
            guard let url = URL(string: downloadLink), NSWorkspace.shared().open(url) else { return }
        } else if response == NSAlertSecondButtonReturn {
            guard let url = URL(string: releaseNotesLink), NSWorkspace.shared().open(url) else { return }
        }
    }
}
