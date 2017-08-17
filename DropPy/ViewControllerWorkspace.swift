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

    func loadSettings() {
        log.debug("Load workspace settings now.")
    }

}
