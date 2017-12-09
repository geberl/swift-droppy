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
        self.window?.setFrame(NSMakeRect(0.0, 0.0, 500, 618), display: true)  // 618 for view height of 550 + 41
        self.window?.center()
    }

}
