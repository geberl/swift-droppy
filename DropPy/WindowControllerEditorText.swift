//
//  WindowControllerEditorText.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerEditorText: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        
        NotificationCenter.default.addObserver(self, selector: #selector(WindowControllerEditorText.closeWindow),
                                               name: .closeEditor, object: nil)
    }
    
    @objc func closeWindow(_ notification: Notification) {
        self.close()
    }
}
