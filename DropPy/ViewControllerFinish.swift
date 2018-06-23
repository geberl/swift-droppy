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
    
    @IBAction func onEmailButton(_ sender: NSButton) {
        openWebsite(webUrl: servicesUrls.guentherMail)
    }
    
    @IBAction func onTwitterButton(_ sender: NSButton) {
        openWebsite(webUrl: servicesUrls.twitter)
    }
    
}
