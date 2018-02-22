//
//  ViewControllerSpritekit.swift
//  DropPy
//
//  Created by Günther Eberl on 22.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import SpriteKit
import os.log


class ViewControllerSpritekit: NSViewController {
    
    override func viewWillAppear() {
        super.viewWillAppear()
        os_log("ViewControllerSpritekit loaded", log: logGeneral)
        
        // TODO: Watch Spritekit tutorials on YouTube
        // TODO: Read https://developer.apple.com/documentation/spritekit
    }
}
