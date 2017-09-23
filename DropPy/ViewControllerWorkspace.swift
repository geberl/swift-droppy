//
//  ViewControllerWorkspace.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
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
            if result == NSFileHandlingPanelOKButton {
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
                
                NotificationCenter.default.post(name: Notification.Name("reloadWorkflows"), object: nil)
                NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
            }
        }
    }
    
    @IBAction func onWorkspaceRestoreButton(_ sender: NSButton) {
        guard let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) else { return }
        let fileManager = FileManager.default
        
        // Set temp directory and files, remove them if they already exist.
        let tempPath: String = NSTemporaryDirectory() + "DropPy" + "/"
        makeDirs(path: tempPath)
        let zipPath: String = tempPath + "droppy-workspace-master.zip"
        if isFile(path: zipPath) {
            do {
                try fileManager.removeItem(atPath: zipPath)
            } catch let error {
                log.error(error.localizedDescription)
            }
        }
        let unzipPath: String = tempPath + "droppy-workspace-master" + "/"
        if isDir(path: unzipPath) {
            do {
                try fileManager.removeItem(atPath: unzipPath)
            } catch let error {
                log.error(error.localizedDescription)
            }
        }
        
        // Copy bundled-workspace from assets to the temp directory.
        if let asset = NSDataAsset(name: "bundled-workspace", bundle: Bundle.main) {
            do {
                try asset.data.write(to: URL(fileURLWithPath: zipPath))
                log.debug("Copied bundled asset to '\(zipPath)'.")
            } catch let error {
                log.error(error.localizedDescription)
            }
        }
        
        // Unzip to a subfolder of the temp directory.
        SSZipArchive.unzipFile(atPath: zipPath, toDestination: tempPath)
        log.debug("Unzipped '\(zipPath)' to '\(tempPath)'.")
        
        // Copy to Workspace.
        guard let enumerator: FileManager.DirectoryEnumerator =
            fileManager.enumerator(atPath: unzipPath) else {
                log.error("Directory not found: \(unzipPath)!")
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
                        log.error(error.localizedDescription)
                    }
                }
                do {
                    try fileManager.copyItem(at: srcURL, to: dstURL)
                } catch let error {
                    log.error(error.localizedDescription)
                }
            }
        }
        
        // Clean up.
        do {
            try fileManager.removeItem(atPath: zipPath)
        } catch let error {
            log.error(error.localizedDescription)
        }
        do {
            try fileManager.removeItem(atPath: unzipPath)
        } catch let error {
            log.error(error.localizedDescription)
        }
        
        // Reload workflows.
        NotificationCenter.default.post(name: Notification.Name("reloadWorkflows"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
    }
    
    @IBAction func onOpenGitHubButton(_ sender: NSButton) {
        if let url = URL(string: "https://github.com/geberl/droppy-workspace"), NSWorkspace.shared().open(url) {
            log.debug("GitHub site for droppy-workspace openened.")
        }
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/preferences/workspace"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for Workspace openened.")
        }
    }

    func loadSettings() {
        if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {
            self.workspaceDirectoryTextField.stringValue = workspacePath
        }
        self.bundledVersionTextField.stringValue = AppState.bundledWorkspaceVersion
    }

}
