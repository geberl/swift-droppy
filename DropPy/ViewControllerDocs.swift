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
    
    @IBAction func onDocsButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.docs)
    }
    
}
