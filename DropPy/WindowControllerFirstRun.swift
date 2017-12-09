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
        self.window?.setFrame(NSMakeRect(0.0, 0.0, 500, 605), display: true)  // 610 for view height of 550 + 50.
        self.window?.center()
    }

}
