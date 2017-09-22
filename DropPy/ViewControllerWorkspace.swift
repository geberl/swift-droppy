//
//  ViewControllerWorkspace.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

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
            }
        }
    }
    
    @IBAction func onWorkspaceRestoreButton(_ sender: NSButton) {
        log.debug("restore")
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
