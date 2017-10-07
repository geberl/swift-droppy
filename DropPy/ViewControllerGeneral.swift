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

    @IBOutlet weak var updateDeltaPopUp: NSPopUpButton!

    @IBAction func onUpdateDeltaPopUp(_ sender: NSPopUpButton) {
        if (self.updateDeltaPopUp.selectedItem != nil) {
            var updateDeltaValue = UserDefaultStruct.updateDeltaDefault
            if let selectedItem = self.updateDeltaPopUp.selectedItem {
                if selectedItem.title == "Every day" {
                    updateDeltaValue = 60 * 60 * 24
                } else if selectedItem.title == "Every week" {
                    updateDeltaValue = 60 * 60 * 24 * 7
                } else if selectedItem.title == "Every month" {
                    updateDeltaValue = 60 * 60 * 24 * 7 * 4
                } else {
                    updateDeltaValue = 60 * 60 * 24 * 7 * 4 * 12 * 10  // ten years
                }
            }
            self.userDefaults.set(updateDeltaValue, forKey: UserDefaultStruct.updateDelta)
        } else {
            self.userDefaults.set(UserDefaultStruct.updateDeltaDefault, forKey: UserDefaultStruct.updateDelta)
        }
    }

    @IBAction func onHelpButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.prefsGeneral)
    }

    func loadSettings() {
        self.radioEnableDevMode.state = NSControl.StateValue(rawValue: Int(truncating: userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) as NSNumber))
        self.adjustIntermediaryFilesLabel()

        let updateDelta: Int = userDefaults.integer(forKey: UserDefaultStruct.updateDelta)
        if updateDelta == 60 * 60 * 24 {
            self.updateDeltaPopUp.selectItem(withTitle: "Every day")
        } else if updateDelta == 60 * 60 * 24 * 7 {
            self.updateDeltaPopUp.selectItem(withTitle: "Every week")
        } else if updateDelta == 60 * 60 * 24 * 7 * 4 {
            self.updateDeltaPopUp.selectItem(withTitle: "Every month")
        } else {
            self.updateDeltaPopUp.selectItem(withTitle: "Never")
        }
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
