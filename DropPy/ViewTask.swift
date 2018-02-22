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
    
    var firstMouseDownPoint: NSPoint = NSZeroPoint
    
    init() {
        super.init(frame: NSZeroRect)
        os_log("ViewTask init", log: logGeneral)
        
        self.frame = CGRect(x: 10, y: 20, width: 50, height: 50)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.red.cgColor
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.layer?.backgroundColor = NSColor.orange.cgColor
        firstMouseDownPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
    }
    
    override func mouseDragged(with event: NSEvent) {
        let newPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        let offset = NSPoint(x: newPoint.x - firstMouseDownPoint.x,
                             y: newPoint.y - firstMouseDownPoint.y)
        let origin = self.frame.origin
        let size = self.frame.size
        let parentSize = self.superview!.frame.size
        
        var positionX: CGFloat
        if origin.x + offset.x < 0 {
            // Dragging left of left border.
            positionX = 0
        } else if origin.x + offset.x + size.width > parentSize.width {
            // Dragging right of right border.
            positionX = parentSize.width - size.width
        } else {
            // Dragging within ok area.
            positionX = origin.x + offset.x
        }
        
        var positionY: CGFloat
        if origin.y + offset.y < 0 {
            // Dragging below bottom border.
            positionY = 0
        } else if origin.y + offset.y + size.height > parentSize.height {
            // Dragging above top border.
            positionY = parentSize.height - size.height
        } else {
            // Dragging within ok area.
            positionY = origin.y + offset.y
        }

        self.frame = NSRect(x: positionX, y: positionY, width: size.width, height: size.height)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        self.layer?.backgroundColor = NSColor.red.cgColor
    }
}
