//
//  ViewControllerDocs.swift
//  DropPy
//
//  Created by Günther Eberl on 04.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerDocs: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onCancelButton(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        let parentTabViewController: NSTabViewController = self.parent! as! NSTabViewController
        
        parentTabViewController.transitionOptions = [NSViewController.TransitionOptions.slideBackward,
                                                     NSViewController.TransitionOptions.crossfade]
        
        parentTabViewController.tabView.selectTabViewItem(at: 1)
    }
    
    @IBAction func onNextButton(_ sender: NSButton) {
        let parentTabViewController: NSTabViewController = self.parent! as! NSTabViewController
        
        parentTabViewController.transitionOptions = [NSViewController.TransitionOptions.slideForward,
                                                     NSViewController.TransitionOptions.crossfade]
        
        parentTabViewController.tabView.selectTabViewItem(at: 3)
    }
    
    
    
}
