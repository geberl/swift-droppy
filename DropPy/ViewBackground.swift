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
    
    override func viewWillDraw() {
        super.viewWillDraw()
        os_log("ViewBackground viewWillDraw", log: logGeneral)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewBackground.addTask),
                                               name: .addTask, object: nil)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        os_log("ViewBackground draw", log: logGeneral)
            
        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor.darkGray.cgColor
    }
    
    @objc func addTask(_ notification: Notification) {
        os_log("addTask", log: logGeneral)
        
        let myTask = ViewTask()
        self.addSubview(myTask)
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        os_log("ViewBackground mouseDown", log: logGeneral)
        
        var firstMouseDownPoint: NSPoint = NSZeroPoint
        firstMouseDownPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        print(firstMouseDownPoint)
        // Origin is always BOTTOM LEFT !
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        os_log("ViewBackground mouseUp", log: logGeneral)
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDown(with: event)
        os_log("ViewBackground mouseDragged", log: logGeneral)
        
        var currentMousePoint: NSPoint = NSZeroPoint
        currentMousePoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        print(currentMousePoint)
    }
}
