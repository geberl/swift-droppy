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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSettings()
    }

    @IBAction func onWorkspaceChangeButton(_ sender: NSButton) {
        print("onWorkspaceChangeButton")
    }
    
    func loadSettings() {
        if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {
            self.workspaceDirectoryTextField.stringValue = workspacePath
        } else {
            print("key not found, using default")
        }
    }
    
}
