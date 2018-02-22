//
//  ViewControllerRects.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerRects: NSViewController {
    
    override func viewWillAppear() {
        super.viewWillAppear()
        os_log("ViewControllerRects viewWillAppear", log: logGeneral)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        os_log("ViewControllerRects viewDidAppear", log: logGeneral)
    }
    
    @IBAction func onCreateButton(_ sender: NSButton) {
        os_log("onCreateButton", log: logGeneral)
        NotificationCenter.default.post(name: .addTask, object: nil)
    }
    
}
