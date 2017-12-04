//
//  ViewControllerWelcome.swift
//  DropPy
//
//  Created by Günther Eberl on 04.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerWelcome: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onCancelButton(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }
    
    @IBAction func onNextButton(_ sender: NSButton) {
        let parentTabViewController:NSTabViewController = self.parent! as! NSTabViewController
        parentTabViewController.tabView.selectTabViewItem(at: 1)
    }
    
}
