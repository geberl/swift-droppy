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
        self.adjustIntermediaryFilesLabel()
    }
    
    @IBOutlet weak var intermediaryFilesTextField: NSTextField!
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/settings/general"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for General openened.")
        }
    }
    
    func loadSettings() {
        self.radioEnableDevMode.state = Int(userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) as NSNumber)
        self.adjustIntermediaryFilesLabel()
    }
    
    func adjustIntermediaryFilesLabel() {
        if self.radioEnableDevMode.state == 1 {
            let intermediaryFilesDir: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/temp"
            self.intermediaryFilesTextField.stringValue = "Intermediary files will be saved to:\n\"\(intermediaryFilesDir)\""
        } else {
            self.intermediaryFilesTextField.stringValue = "Intermediary files will not be saved."
        }
    }
}
