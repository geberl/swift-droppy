//
//  ViewControllerFirstRun.swift
//  DropPy
//
//  Created by Günther Eberl on 03.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerFirstRun: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onCloseButton(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }

}
