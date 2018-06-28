//
//  ViewControllerGeneral.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerGeneral: NSViewController {

    let userDefaults = UserDefaults.standard

    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }

    @IBOutlet weak var radioEnableDevMode: NSButton!

    @IBAction func onRadioEnableDevMode(_ sender: Any) {
        let devModeEnabled = Bool(truncating: self.radioEnableDevMode.state as NSNumber)
        self.userDefaults.set(devModeEnabled, forKey: UserDefaultStruct.devModeEnabled)

        self.adjustIntermediaryFilesLabel()
        
        NotificationCenter.default.post(name: .devModeChanged, object: nil)
    }

    @IBOutlet weak var intermediaryFilesTextField: NSTextField!

    @IBAction func onHelpButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.prefsGeneral)
    }

    func loadSettings() {
        self.radioEnableDevMode.state = NSControl.StateValue(rawValue: Int(truncating: userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) as NSNumber))
        self.adjustIntermediaryFilesLabel()
    }

    func adjustIntermediaryFilesLabel() {
        if self.radioEnableDevMode.state.rawValue == 1 {
            self.intermediaryFilesTextField.stringValue = "Intermediary files will be saved until program exit.\n"
            self.intermediaryFilesTextField.stringValue += "After running a Workflow some buttons to help you debugging will appear."
        } else {
            self.intermediaryFilesTextField.stringValue = "Intermediary files will not be saved."
        }
    }
}
