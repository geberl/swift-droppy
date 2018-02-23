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
    
    @IBAction func onAddButton(_ sender: NSButton) {
        os_log("onAddButton", log: logGeneral)
        NotificationCenter.default.post(name: .addTask, object: nil)
    }
    
    @IBAction func onRemoveButton(_ sender: NSButton) {
        os_log("onRemoveButton", log: logGeneral)
        NotificationCenter.default.post(name: .removeTask, object: nil)
    }
    
}
