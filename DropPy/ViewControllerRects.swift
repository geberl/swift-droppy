//
//  ViewControllerRects.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


// Useful resource:
// https://stackoverflow.com/questions/46097132/how-to-move-nsimageview-inside-nsview-in-cocoa


class ViewControllerRects: NSViewController {
    
    override func viewWillAppear() {
        super.viewWillAppear()
        os_log("ViewControllerRects viewWillAppear", log: logGeneral)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        os_log("ViewControllerRects viewDidAppear", log: logGeneral)
        
//        let theRectangle = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//        theRectangle.wantsLayer = true
//        theRectangle.layer!.backgroundColor = NSColor.red.cgColor
//        self.view.addSubview(theRectangle)
        
    }
    
    @IBAction func onCreateButton(_ sender: NSButton) {
        os_log("onCreateButton", log: logGeneral)
        NotificationCenter.default.post(name: .addTask, object: nil)
    }
    
}
