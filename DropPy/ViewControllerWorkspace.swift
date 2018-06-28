//
//  ViewControllerWorkspace.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


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
        panel.canCreateDirectories = true
        
        panel.beginSheetModal(for: window) { (result) in
            if result == NSApplication.ModalResponse.OK {
                let selectedFolder: URL = panel.urls[0]
                let selectedPath: String = selectedFolder.path
                self.workspaceDirectoryTextField.stringValue = selectedPath
                self.userDefaults.set(selectedPath, forKey: UserDefaultStruct.workspacePath)
                
                createWorkspaceDirStructure(workspacePath: selectedPath)
                
                NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
                NotificationCenter.default.post(name: .workflowSelectionChanged, object: nil)
            }
        }
    }
    
    @IBAction func onWorkspaceRestoreButton(_ sender: NSButton) {
        guard let workspacePath = checkWorkspaceInfo() else { return }
        extractBundledWorkspace(workspacePath: workspacePath)
        
        // Reload workflows.
        NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
        NotificationCenter.default.post(name: .workflowSelectionChanged, object: nil)
    }
    
    @IBAction func onOpenGitHubButton(_ sender: NSButton) {
        openWebsite(webUrl: servicesUrls.githubWorkspace)
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
