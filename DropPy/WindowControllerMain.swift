//
//  WindowControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 04.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class WindowControllerMain: NSWindowController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var ToolbarDropdown: NSMenu!

    @IBOutlet weak var workflowPopUp: NSPopUpButton!

    @IBOutlet weak var actionButtons: NSSegmentedControl!
    
    @IBAction func ToolbarActions(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.editWorkflow(nil)
        }
        else if sender.selectedSegment == 1 {
            self.openFinder(nil)
        }
        else if sender.selectedSegment == 2 {
            self.addWorkflow(nil)
        }
    }

    lazy var textEditorWindowController: WindowControllerEditorText  = {
        let wcSB = NSStoryboard(name: "EditorText", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerEditorText
    }()
    
    lazy var workflowEditorWindowController: WindowControllerEditorWorkflow  = {
        let wcSB = NSStoryboard(name: "EditorWorkflow", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerEditorWorkflow
    }()
    
    override func windowWillLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.refreshToolbarDropdown),
                                               name: .workflowsChanged, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.disableToolbar),
                                               name: .droppingStarted, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.enableToolbar),
                                               name: .executionFinished, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.evaluateWorkflowResults),
                                               name: .executionFinished, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.workflowIdenticalNameAlert),
                                               name: .workflowIdenticalName, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.addWorkflow),
                                               name: .workflowNew, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.editWorkflow),
                                               name: .workflowEdit, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.openFinder),
                                               name: .workflowDirOpen, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerMain.askDeleteWorkflow),
                                               name: .workflowDelete, object: nil)
    }
    
    @objc func disableToolbar(_ notification: Notification){
        workflowPopUp.isEnabled = false
        actionButtons.setEnabled(false, forSegment: 0)
        actionButtons.setEnabled(false, forSegment: 1)
        actionButtons.setEnabled(false, forSegment: 2)
    }
    
    @objc func enableToolbar(_ notification: Notification){
        workflowPopUp.isEnabled = true
        actionButtons.setEnabled(true, forSegment: 0)
        actionButtons.setEnabled(true, forSegment: 1)
        actionButtons.setEnabled(true, forSegment: 2)
    }

    @objc func refreshToolbarDropdown(_ notification: Notification){
        self.refreshToolbar()
    }

    func refreshToolbar() {
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

    @objc func workflowSelectionChanged() {
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
        NotificationCenter.default.post(name: .workflowSelectionChanged, object: nil)
    }

    @objc func openFinder(_ notification: Notification?) {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        guard let jsonFile: String = AppState.activeJsonFile else { return }

        NSWorkspace.shared.selectFile(workspacePath + "Workflows" + "/" + jsonFile,
                                      inFileViewerRootedAtPath: workspacePath)
    }
    
    @objc func askDeleteWorkflow(_ notification: Notification?) {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        guard let jsonFile: String = AppState.activeJsonFile else { return }
        guard let jsonName: String = AppState.activeName else { return }

        let warningAlert = NSAlert()
        warningAlert.showsHelp = false
        warningAlert.messageText = "Delete Workflow '" + jsonName + "'"
        warningAlert.informativeText = "Are you sure you want to remove this Workflow?"
        warningAlert.addButton(withTitle: "Cancel")
        warningAlert.addButton(withTitle: "Move to Trash")
        warningAlert.layout()
        warningAlert.alertStyle = NSAlert.Style.warning
        warningAlert.icon = NSImage(named: "alert")
        
        warningAlert.beginSheetModal(for: self.window!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                os_log("Deleting workflow '%@'", log: logUi, type: .debug, jsonName)
                self.deleteWorkflow(workflowPath: workspacePath + "Workflows" + "/" + jsonFile)
            } else {
                os_log("User clicked 'Cancel' on delete Workflow alert.'", log: logUi, type: .debug)
            }
        })
    }
    
    func deleteWorkflow(workflowPath: String) {
        trashDirOrFile(path: workflowPath)
        NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
    }
    
    @objc func editWorkflow(_ notification: Notification?) {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        guard let jsonFile: String = AppState.activeJsonFile else { return }
        
        let jsonPath: String = workspacePath + "Workflows" + "/" + jsonFile
        
        if let editorForWorkflows: String = self.userDefaults.string(forKey: UserDefaultStruct.editorForWorkflows) {
            
            if editorForWorkflows == "Internal workflow editor" {
                self.workflowEditorWindowController.showWindow(self)
                
                // Put path into dict inside Notification.
                let pathDict:[String: String] = ["path": jsonPath]
                NotificationCenter.default.post(name: .loadFileInEditor, object: nil, userInfo: pathDict)
                
            } else if editorForWorkflows == "Internal text editor" {
                self.textEditorWindowController.showWindow(self)
                
                // Put path into dict inside Notification.
                let pathDict:[String: String] = ["path": jsonPath]
                NotificationCenter.default.post(name: .loadFileInEditor, object: nil, userInfo: pathDict)
                
            } else if editorForWorkflows == "External text editor" {
                guard let editorAppPath: String = self.userDefaults.string(forKey: UserDefaultStruct.editorAppPath) else { return }
                if isDir(path: editorAppPath) {
                    // Passing custom parameters to the external editor is currently not possible.
                    NSWorkspace.shared.openFile(jsonPath, withApplication: editorAppPath)
                } else {
                    NotificationCenter.default.post(name: .editorNotFound, object: nil)
                }
            }
        }
    }
    
    @objc func addWorkflow(_ notification: Notification?) {
        os_log("Adding new workflow", log: logUi, type: .debug)
        
        guard let workspacePath = checkWorkspaceInfo() else { return }
        let isoDateString = Date().iso8601like
        let workflowFileName: String = "new_workflow_\(isoDateString).json"
        let workflowName: String = "New Workflow \(isoDateString)"
        let workflowFileUrl: URL = URL(fileURLWithPath: workspacePath + "Workflows" + "/" + workflowFileName)
        os_log("Workflow path: %@", log: logFileSystem, type: .debug, workflowFileUrl.path)
        
        // Create empty text file.
        do {
            try "".write(to: workflowFileUrl, atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            os_log("%@", log: logFileSystem, type: .error, error.localizedDescription)
            return
        }
        
        // Fill file with standard content.
        if let fileHandle = FileHandle(forWritingAtPath: workflowFileUrl.path) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write("{\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"name\": \"\(workflowName)\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"author\": \"your@email.here\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"description\": \"Optional. A short description what this Workflow does.\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"documentation\": \"https://docs.droppyapp.com/workflows/\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"image\": \"default.png\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"interpreterName\": \"\(AppState.interpreterStockName)\",\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  \"queue\": [\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("  ]\n".data(using: String.Encoding.utf8)!)
            fileHandle.write("}\n".data(using: String.Encoding.utf8)!)
        }
        
        // Update global Workflow object.
        AppState.activeInterpreterName = AppState.interpreterStockName
        AppState.activeJsonFile = workflowFileName
        AppState.activeName = workflowName
        AppState.activeLogoFile = nil
        
        // Open new file in editor.
        self.editWorkflow(nil)
    }

    @objc func evaluateWorkflowResults(_ notification: Notification) {
        guard let timestampDirPath = notification.userInfo?["timestampDirPath"] as? String else { return }
        guard let exitCode = notification.userInfo?["exitCode"] as? String else { return }
        
        if Int(exitCode)! > 0 {
            self.executionErrorAlert(timestampDirPath: timestampDirPath)
        }
    }

    func executionErrorAlert(timestampDirPath: String) {
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "Running one of your Tasks failed"
        errorAlert.informativeText = "Take a look in the log file for details."
        errorAlert.addButton(withTitle: "Ok")
        errorAlert.addButton(withTitle: "Open log file")
        errorAlert.addButton(withTitle: "Open temp dir")
        errorAlert.layout()
        errorAlert.alertStyle = NSAlert.Style.warning
        errorAlert.icon = NSImage(named: "error")
        
        let logFilePath = timestampDirPath + "droppy.log"
        
        errorAlert.beginSheetModal(for: self.window!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                self.openFileInDefaultApp(filePath: logFilePath)
            } else if returnCode == NSApplication.ModalResponse.alertThirdButtonReturn {
                var rootDirPath: String
                if let tempDirPath = AppState.tempDirPath {
                    rootDirPath = tempDirPath
                } else {
                    rootDirPath = timestampDirPath
                }
                self.openFileInFinder(filePath: logFilePath, rootDir: rootDirPath)
            }
        })
    }

    func openFileInFinder(filePath: String, rootDir: String) {
        NSWorkspace.shared.selectFile(filePath, inFileViewerRootedAtPath: rootDir)
    }
    
    func openFileInDefaultApp(filePath: String) {
        NSWorkspace.shared.openFile(filePath)
    }
    
    @objc func workflowIdenticalNameAlert(_ notification: Notification) {
        guard let workflowName = notification.userInfo?["workflowName"] as? String else { return }
        guard let workflowLoadedPath = notification.userInfo?["workflowLoadedPath"] as? String else { return }
        guard let workflowSkippedPath = notification.userInfo?["workflowSkippedPath"] as? String else { return }
        
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = "Workflow name '" + workflowName + "' already in use"
        errorAlert.informativeText = "You can't use the same Workflow name multiple times.\n\n"
        errorAlert.informativeText += "The Workflow '" + workflowLoadedPath + "' was loaded, "
        errorAlert.informativeText += "but '" + workflowSkippedPath + "' was skipped.\n\n"
        errorAlert.informativeText += "Edit the 'name' property in one of those JSON files to get rid of this warning."
        errorAlert.addButton(withTitle: "Ok")
        errorAlert.layout()
        errorAlert.alertStyle = NSAlert.Style.warning
        errorAlert.icon = NSImage(named: "alert")
        errorAlert.beginSheetModal(for: self.window!)
    }
}
