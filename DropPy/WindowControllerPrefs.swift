//
//  PreferencesWindowController.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa


class WindowControllerPrefs: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.setFrame(NSMakeRect(0.0, 0.0, 750, 230), display: true)
        self.window?.center()
    }
    
    func switchToPrefTab(index: Int, messageText: String, informativeText: String) {
        let userInfo:[String: Any] = ["index": index,
                                      "messageText": messageText,
                                      "informativeText": informativeText]
        NotificationCenter.default.post(name: .switchToPrefTab, object: nil, userInfo: userInfo)
    }
}
