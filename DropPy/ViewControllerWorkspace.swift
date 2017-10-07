//
//  ViewControllerWorkspace.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log
import SSZipArchive


class ViewControllerWorkspace: NSViewController {
    
    let userDefaults = UserDefaults.standard

    @IBOutlet weak var workspaceDirectoryTextField: NSTextField!
    @IBOutlet weak var bundledVersionTextField: NSTextField!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }
    
    @IBAction func onWorkspaceChangeButton(_ sender: NSButton) {
        guard let window = view.window else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                let selectedFolder: URL = panel.urls[0]
                let selectedPath: String = selectedFolder.path
                self.workspaceDirectoryTextField.stringValue = selectedPath
                self.userDefaults.set(selectedPath, forKey: UserDefaultStruct.workspacePath)
                
                if !isDir(path: selectedPath + "/" + "Images") {
                    makeDirs(path: selectedPath + "/" + "Images")
                }
                if !isDir(path: selectedPath + "/" + "Tasks") {
                    makeDirs(path: selectedPath + "/" + "Tasks")
                }
                if !isDir(path: selectedPath + "/" + "Workflows") {
                    makeDirs(path: selectedPath + "/" + "Workflows")
                }
                
                NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
                NotificationCenter.default.post(name: .workflowSelectionChanged, object: nil)
            }
        }
    }
    
    @IBAction func onWorkspaceRestoreButton(_ sender: NSButton) {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        let fileManager = FileManager.default
        
        // Set temp directory and files, remove them if they already exist.
        let tempPath: String = NSTemporaryDirectory() + "se.eberl.droppy" + "/"
        makeDirs(path: tempPath)
        let zipPath: String = tempPath + "droppy-workspace-master.zip"
        if isFile(path: zipPath) {
            do {
                try fileManager.removeItem(atPath: zipPath)
            } catch let error {
                os_log("%@", log: logUi, type: .error, error.localizedDescription)
            }
        }
        let unzipPath: String = tempPath + "droppy-workspace-master" + "/"
        if isDir(path: unzipPath) {
            do {
                try fileManager.removeItem(atPath: unzipPath)
            } catch let error {
                os_log("%@", log: logUi, type: .error, error.localizedDescription)
            }
        }
        
        // Copy bundled-workspace from assets to the temp directory.
        if let asset = NSDataAsset(name: NSDataAsset.Name(rawValue: "bundled-workspace"), bundle: Bundle.main) {
            do {
                try asset.data.write(to: URL(fileURLWithPath: zipPath))
                os_log("Copied bundled asset to '%@'.", log: logFileSystem, type: .error, zipPath)
            } catch let error {
                os_log("%@", log: logUi, type: .error, error.localizedDescription)
            }
        }
        
        // Unzip to a subfolder of the temp directory.
        SSZipArchive.unzipFile(atPath: zipPath, toDestination: tempPath)
        os_log("Unzipped '%@' to '%@'.", log: logFileSystem, type: .error, zipPath, tempPath)
        
        // Copy to Workspace.
        guard let enumerator: FileManager.DirectoryEnumerator =
            fileManager.enumerator(atPath: unzipPath) else {
                os_log("Directory not found at '%@'.", log: logFileSystem, type: .error, unzipPath)
                return
        }

        while let element = enumerator.nextObject() as? String {
            var srcURL: URL = URL(fileURLWithPath: unzipPath)
            srcURL.appendPathComponent(element)
            var dstURL: URL = URL(fileURLWithPath: workspacePath)
            dstURL.appendPathComponent(element)
            
            // Create directories.
            if isDir(path: srcURL.path) {
                if !isDir(path: dstURL.path) {
                    makeDirs(path: dstURL.path)
                }
            }
            
            // Copy files (after removing their previous version).
            if isFile(path: srcURL.path){
                if isFile(path: srcURL.path){
                    do {
                        try fileManager.removeItem(at: dstURL)
                    } catch let error {
                        os_log("%@", log: logUi, type: .error, error.localizedDescription)
                    }
                }
                do {
                    try fileManager.copyItem(at: srcURL, to: dstURL)
                } catch let error {
                    os_log("%@", log: logUi, type: .error, error.localizedDescription)
                }
            }
        }
        
        // Clean up.
        do {
            try fileManager.removeItem(atPath: zipPath)
        } catch let error {
            os_log("%@", log: logUi, type: .error, error.localizedDescription)
        }
        do {
            try fileManager.removeItem(atPath: unzipPath)
        } catch let error {
            os_log("%@", log: logUi, type: .error, error.localizedDescription)
        }
        
        // Reload workflows.
        NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
        NotificationCenter.default.post(name: .workflowSelectionChanged, object: nil)
    }
    
    @IBAction func onOpenGitHubButton(_ sender: NSButton) {
        openWebsite(webUrl: githubUrls.workspace)
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.prefsWorkspace)
    }

    func loadSettings() {
        if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {
            self.workspaceDirectoryTextField.stringValue = workspacePath
        }
        self.bundledVersionTextField.stringValue = AppState.bundledWorkspaceVersion
    }

}
