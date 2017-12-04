//
//  ViewControllerWorkspaceSetup.swift
//  DropPy
//
//  Created by Günther Eberl on 04.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerWorkspaceSetup: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onCancelButton(_ sender: NSButton) {
        let application = NSApplication.shared
        application.stopModal()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        let parentTabViewController:NSTabViewController = self.parent! as! NSTabViewController
        parentTabViewController.tabView.selectTabViewItem(at: 0)
    }

    @IBAction func onNextButton(_ sender: NSButton) {
        let parentTabViewController:NSTabViewController = self.parent! as! NSTabViewController
        parentTabViewController.tabView.selectTabViewItem(at: 2)
    }

}