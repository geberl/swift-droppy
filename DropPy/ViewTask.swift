//
//  ViewTask.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewTask: NSView {
    
    init() {
        super.init(frame: NSZeroRect)
        os_log("ViewTask init", log: logGeneral)
        
        self.frame = CGRect(x: 10, y: 20, width: 10, height: 10)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.red.cgColor
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        os_log("ViewTask mouseDown", log: logGeneral)
    }
    
}
