//
//  WindowControllerEditorWorkflow.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerEditorWorkflow: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerEditorWorkflow.closeWindow),
                                               name: .closeEditor, object: nil)
    }
    
    @objc func closeWindow(_ notification: Notification) {
        self.close()
    }
}
