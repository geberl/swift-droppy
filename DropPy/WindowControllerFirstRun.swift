//
//  WindowControllerFirstRun.swift
//  DropPy
//
//  Created by Günther Eberl on 03.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class WindowControllerFirstRun: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.setFrame(NSMakeRect(0.0, 0.0, 550, 400), display: true)
        self.window?.center()
        self.window?.title = ""
    }

}
