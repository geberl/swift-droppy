//
//  ViewControllerInterpreter.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//


import Cocoa

class ViewControllerInterpreter: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }
    
    @IBAction func onPlusButton(_ sender: Any) {
        log.debug("Add an interpreter/env now.")
    }
    
    @IBAction func onMinusButton(_ sender: Any) {
        log.debug("Remove selected interpreter/env now.")
    }
    
    func loadSettings() {
        log.debug("Load interpreter settings now.")
    }
}
