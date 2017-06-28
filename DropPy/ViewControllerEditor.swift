//
//  ViewControllerEditor.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerEditor: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.applySettings()
    }

    @IBAction func onButtonRestoreDefault(_ sender: NSButton) {
        userDefaults.set(UserDefaultStruct.editorAppDefault, forKey: UserDefaultStruct.editorApp)
    }
    
    @IBOutlet weak var radioInternal: NSButton!
    
    @IBOutlet weak var radioExternal: NSButton!

    @IBAction func onRadioWorkflowEditor(_ sender: NSButton) {
        if sender.title == "External text editor" {
            userDefaults.set(true, forKey: UserDefaultStruct.useTextEditorForWorkflows)
            }
        if sender.title == "Internal Workflow editor" {
            userDefaults.set(false, forKey: UserDefaultStruct.useTextEditorForWorkflows)
        }
    }
    
    func applySettings() {
        if userDefaults.bool(forKey: UserDefaultStruct.useTextEditorForWorkflows) == true {
            radioInternal.state = 0
            radioExternal.state = 1
        } else {
            radioInternal.state = 1
            radioExternal.state = 0
        }
    }
}
