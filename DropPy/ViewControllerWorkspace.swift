//
//  ViewControllerWorkspace.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerWorkspace: NSViewController {
    
    let userDefaults = UserDefaults.standard

    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/settings/workspace"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for Workspace openened.")
        }
    }

    func loadSettings() {
        log.debug("Load workspace settings now.")
    }

}
