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
    
    let uuid = NSUUID().uuidString
    var firstMouseDownPoint: NSPoint = NSZeroPoint
    
    init() {
        super.init(frame: NSZeroRect)
        os_log("ViewTask %@ init", log: logGeneral, self.uuid)
        
        self.frame = CGRect(x: 10, y: 20, width: 300, height: 50)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
        self.layer?.borderColor = NSColor.blue.cgColor
        
        let label = NSTextField(frame: CGRect(x: 0, y: 13, width: 300, height: 21))
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.textColor = .black
        label.stringValue = uuid
        label.alignment = .center
        self.addSubview(label)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewTask.selectionBorder),
                                               name: .selectTask, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewTask.remove),
                                               name: .removeTask, object: nil)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func selectionBorder(_  notification: Notification) {
        guard let uuidToSelect = notification.userInfo?["selectedTask"] as? String else { return }
        
        if self.uuid == uuidToSelect {
            self.layer?.borderWidth = 4
        } else {
            self.layer?.borderWidth = 0
        }
    }
    
    @objc func remove(_  notification: Notification) {
        // Check if item is selected.
        if self.layer!.borderWidth > 0 {
            self.removeFromSuperview()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.layer?.backgroundColor = NSColor.gray.cgColor
        firstMouseDownPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        
        let selectionDict: [String: String] = ["selectedTask": self.uuid]
        NotificationCenter.default.post(name: .selectTask, object: nil, userInfo: selectionDict)
    }
    
    override func mouseDragged(with event: NSEvent) {
        let newPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        let offset = NSPoint(x: newPoint.x - firstMouseDownPoint.x,
                             y: newPoint.y - firstMouseDownPoint.y)
        let origin = self.frame.origin
        let size = self.frame.size
        
        let backgroundView = self.superview as! ViewBackground
        let backgroundSize = backgroundView.frame.size
        
        var positionX: CGFloat
        if origin.x + offset.x < 0 {
            // Dragging left of left border.
            positionX = 0
        } else if origin.x + offset.x + size.width > backgroundSize.width {
            // Dragging right of right border.
            positionX = backgroundSize.width - size.width
        } else {
            // Dragging within ok area.
            positionX = origin.x + offset.x
        }
        
        var positionY: CGFloat
        if origin.y + offset.y < 0 {
            // Dragging below bottom border.
            positionY = 0
        } else if origin.y + offset.y + size.height > backgroundSize.height {
            // Dragging above top border.
            positionY = backgroundSize.height - size.height
        } else {
            // Dragging within ok area.
            positionY = origin.y + offset.y
        }
        
        if backgroundView.snapToGrid == true {
            positionX = CGFloat( Int(positionX / backgroundView.gridSize) * Int(backgroundView.gridSize) )
            positionY = CGFloat( Int(positionY / backgroundView.gridSize) * Int(backgroundView.gridSize) )
        }

        self.frame = NSRect(x: positionX, y: positionY, width: size.width, height: size.height)
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
}
