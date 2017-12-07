//
//  ViewControllerFinish.swift
//  DropPy
//
//  Created by Günther Eberl on 04.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerFinish: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        let parentTabViewController: NSTabViewController = self.parent! as! NSTabViewController
        
        parentTabViewController.transitionOptions = [NSViewController.TransitionOptions.slideBackward,
                                                     NSViewController.TransitionOptions.crossfade]
        
        parentTabViewController.tabView.selectTabViewItem(at: 2)
    }
    
    @IBAction func onFinishButton(_ sender: Any) {
        let application = NSApplication.shared
        application.stopModal()
    }
    
}
