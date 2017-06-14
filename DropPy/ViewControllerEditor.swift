//
//  ViewControllerEditor.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerEditor: NSViewController {
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.applySettings()
    }

    @IBAction func onButtonRestoreDefault(_ sender: NSButton) {
        Settings.editor = "TextEdit"
    }
    
    @IBOutlet weak var radioInternal: NSButton!
    
    @IBOutlet weak var radioExternal: NSButton!

    @IBAction func onRadioWorkflowEditor(_ sender: NSButton) {
        if sender.title == "External text editor" {
            Settings.useTextEditorForWorkflows = true
            }
        if sender.title == "Internal Workflow editor" {
            Settings.useTextEditorForWorkflows = false
        }
    }
    
    func applySettings() {
        if Settings.useTextEditorForWorkflows == true {
            radioInternal.state = 0
            radioExternal.state = 1
        } else {
            radioInternal.state = 1
            radioExternal.state = 0
        }
    }
}
