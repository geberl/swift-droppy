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
        let devModeEnabled = Bool(self.radioEnableDevMode.state as NSNumber)
        self.userDefaults.set(devModeEnabled, forKey: UserDefaultStruct.devModeEnabled)

        self.adjustIntermediaryFilesLabel()

        if !devModeEnabled {
            let tempPath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/" + "Temp" + "/"
            if isDir(path: tempPath) {
                self.askDeleteTempAlert(tempPath: tempPath)
            }
        }
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
        if let url = URL(string: "https://droppyapp.com/settings/general"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for General openened.")
        }
    }

    func loadSettings() {
        self.radioEnableDevMode.state = Int(userDefaults.bool(forKey: UserDefaultStruct.devModeEnabled) as NSNumber)
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
        if self.radioEnableDevMode.state == 1 {
            let intermediaryFilesDir: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath)! + "/Temp/"
            self.intermediaryFilesTextField.stringValue = "Intermediary files will be saved to:\n\"\(intermediaryFilesDir)\""
        } else {
            self.intermediaryFilesTextField.stringValue = "Intermediary files will not be saved."
        }
    }

    func askDeleteTempAlert(tempPath: String) {
        let myAlert = NSAlert()
        myAlert.showsHelp = false
        myAlert.messageText = "Delete Temp dir"
        myAlert.informativeText = "The directory at '" + tempPath + "' can usually be deleted now."
        myAlert.addButton(withTitle: "Delete")
        myAlert.addButton(withTitle: "Cancel")
        myAlert.layout()
        myAlert.alertStyle = NSAlertStyle.critical
        myAlert.icon = NSImage(named: "alert")

        myAlert.beginSheetModal(for: NSApplication.shared().mainWindow!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSAlertFirstButtonReturn {
                do {
                    let fileManager = FileManager.default
                    try fileManager.removeItem(atPath: tempPath)
                    log.debug("Removed temp dir at \(tempPath)")
                } catch let error {
                    log.error(error.localizedDescription)
                }
            }
        })
    }
}
