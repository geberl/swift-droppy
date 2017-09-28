//
//  WindowControllerEditor.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerEditor: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerEditor.closeWindow),
                                               name: Notification.Name("closeEditor"),
                                               object: nil)
    }
    
    func closeWindow(_ notification: Notification) {
        self.close()
    }

}
