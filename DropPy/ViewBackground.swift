//
//  ViewBackground.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewBackground: NSView {

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)!
        os_log("ViewBackground init", log: logGeneral)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.darkGray.cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewBackground.addTask),
                                               name: .addTask, object: nil)
    }
    
    @objc func addTask(_ notification: Notification) {
        os_log("addTask", log: logGeneral)
        
        let myTask = ViewTask()
        self.addSubview(myTask)
    }

}
