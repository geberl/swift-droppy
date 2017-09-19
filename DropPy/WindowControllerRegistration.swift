//
//  WindowControllerRegistration.swift
//  DropPy
//
//  Created by Günther Eberl on 30.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerRegistration: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerRegistration.closeWindow(notification:)),
                                               name: Notification.Name("closeRegistration"),
                                               object: nil)
    }
    
    func closeWindow(notification: Notification) {
        self.close()
    }
}
