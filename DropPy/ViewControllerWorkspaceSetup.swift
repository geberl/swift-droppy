//
//  ViewControllerWorkspaceSetup.swift
//  DropPy
//
//  Created by Günther Eberl on 04.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerWorkspaceSetup: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var workspaceDirectoryTextField: NSTextField!
    @IBOutlet weak var workspaceChangeButton: NSButton!
    @IBOutlet weak var defaultContentCheckbox: NSButton!
    @IBOutlet weak var defaultContentDescription: NSTextField!
    @IBOutlet weak var defaultContentNotice: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setWorkspacePath()  // triggered only once on load,.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setCheckbox()  // triggered on each slide forward/back that displays that tab.
    }

    @IBAction func onWorkspaceChangeButton(_ sender: NSButton) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSFileHandlingPanelOKButton {
                let selectedFolder: URL = panel.urls[0]
                let selectedPath: String = selectedFolder.path
                
                // Adjust path in text field.
                self.workspaceDirectoryTextField.stringValue = selectedPath
                
                // Save path as key in UserDefaults.
                self.userDefaults.set(selectedPath, forKey: UserDefaultStruct.workspacePath)
            }
        }
    }
    
    func getDefaultContentCheckboxValue() -> Bool {
        return Bool(truncating: self.defaultContentCheckbox.state as NSNumber)
    }
    
    func setCheckbox() {
        if AppState.initialSetupCompleted {
            // Set the workspace change button to disabled.
            self.workspaceChangeButton.isEnabled = false
            
            // Set the checkbox to unchecked and unchangeable. Extracting default contents again here is ambiguous.
            self.defaultContentCheckbox.isEnabled = false
            self.defaultContentCheckbox.state = NSControl.StateValue(rawValue: 0)
            self.defaultContentDescription.isHidden = true
            self.defaultContentNotice.isHidden = false
        } else {
            // Set the workspace change button to enabled.
            self.workspaceChangeButton.isEnabled = true
            
            // Allow the checkbox to be edited. Default checked. Notice hidden.
            self.defaultContentCheckbox.isEnabled = true
            self.defaultContentCheckbox.state = NSControl.StateValue(rawValue: 1)
            self.defaultContentDescription.isHidden = false
            self.defaultContentNotice.isHidden = true
        }
    }
    
    func setWorkspacePath() {
        if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {
            // Key already present, workspacePath was set already. Show the actual value in text field.
            self.workspaceDirectoryTextField.stringValue = workspacePath
        } else {
            // Key not present. Show the default value in text field.
            self.workspaceDirectoryTextField.stringValue = UserDefaultStruct.workspacePathDefault
        }
    }
}
