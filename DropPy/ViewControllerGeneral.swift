//
//  ViewControllerGeneral.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerGeneral: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }
    
    @IBOutlet weak var radioEnableDevMode: NSButton!
    
    @IBAction func onRadioEnableDevMode(_ sender: Any) {
        self.userDefaults.set(Bool(self.radioEnableDevMode.state as NSNumber),
                              forKey: UserDefaultStruct.devModeEnabled)
    }
    
    func loadSettings() {
        self.radioEnableDevMode.state = Int(userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) as NSNumber)
    }
}
