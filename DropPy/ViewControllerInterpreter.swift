//
//  ViewControllerInterpreter.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

// Tutorial for tableView:
// https://www.raywenderlich.com/143828/macos-nstableview-tutorial

// Getting cell text editing to work:
// https://stackoverflow.com/questions/33354596/nstableview-detect-nstablecolumn-for-selected-cell-at-start-of-cell-edition

// Modes of NSTableView:
// - cell-based (NSCell), older and lighter (NOT used here)
// - view-based (NSView), more powerful     (used here)

import Cocoa

class ViewControllerInterpreter: NSViewController {
    
    let userDefaults = UserDefaults.standard

    var interpreterNames: [String] = []
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var executableTextField: NSTextField!
    
    @IBOutlet weak var argumentsTextField: NSTextField!
    
    @IBOutlet weak var infoVersionTextField: NSTextField!
    
    @IBOutlet weak var infoSystemDefaultTextField: NSTextField!
    
    @IBOutlet weak var infoVirtualenvTextField: NSTextField!
    
    @IBAction func onPlusButton(_ sender: Any) {
        log.debug("Add an interpreter/env now.")
    }
    
    @IBAction func onMinusButton(_ sender: Any) {
        log.debug("Remove selected interpreter/env now.")
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/settings/interpreter"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for Interpreter openened.")
        }
    }
    
    func loadSettings() {
        if let interpreterDict: Dictionary = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) {
            self.interpreterNames = Array(interpreterDict.keys).sorted()
        }
    }
    
    func updateProperties() {
        if let selectedInterpreterIndex = tableView.selectedRowIndexes.first {
            // There is an item selected in the tableView.
            
            if let allInterpreterDict: Dictionary = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) {
                let selectedInterpreterName:String = self.interpreterNames[selectedInterpreterIndex]
                
                if let selectedInterpreterValues: Dictionary<String, String> = allInterpreterDict[selectedInterpreterName] as? Dictionary {
                    if let executableValue: String = selectedInterpreterValues["executable"] {
                        self.executableTextField.stringValue = executableValue
                        self.executableTextField.isEnabled = true

                        if let versionInfo: String = self.getInfoVersion(executable: executableValue) {
                            self.infoVersionTextField.stringValue = versionInfo
                            self.infoVersionTextField.isEnabled = true
                        } else {
                            self.infoVersionTextField.stringValue = "error"
                            self.infoVersionTextField.isEnabled = false
                        }
                        
                        if let systemDefaultInfo: String = self.getInfoSystemDefault(executable: executableValue) {
                            self.infoSystemDefaultTextField.stringValue = systemDefaultInfo
                            self.infoSystemDefaultTextField.isEnabled = true
                        } else {
                            self.infoSystemDefaultTextField.stringValue = "error"
                            self.infoSystemDefaultTextField.isEnabled = false
                        }
                        
                        if let virtualenvInfo: String = self.getInfoVirtualEnv(executable: executableValue) {
                            self.infoVirtualenvTextField.stringValue = virtualenvInfo
                            self.infoVirtualenvTextField.isEnabled = true
                        } else {
                            self.infoVirtualenvTextField.stringValue = "error"
                            self.infoVirtualenvTextField.isEnabled = false
                        }
                    }
                    
                    if let argumentsValue: String = selectedInterpreterValues["arguments"] {
                        self.argumentsTextField.stringValue = argumentsValue
                        self.argumentsTextField.isEnabled = true
                    }
                }
                
                if selectedInterpreterName == userDefaults.string(forKey: UserDefaultStruct.interpreterStockName) {
                    self.argumentsTextField.isEditable = false
                    self.executableTextField.isEditable = false
                } else {
                    self.argumentsTextField.isEditable = true
                    self.executableTextField.isEditable = true
                }
            }
        } else {
            
            // No item is selected in the tableView.
            self.executableTextField.stringValue = ""
            self.argumentsTextField.stringValue = ""
            
            self.executableTextField.isEnabled = true
            self.argumentsTextField.isEnabled = true
            
            self.infoVersionTextField.stringValue = ""
            self.infoVersionTextField.isEnabled = false
            
            self.infoSystemDefaultTextField.stringValue = ""
            self.infoSystemDefaultTextField.isEnabled = false
            
            self.infoVirtualenvTextField.stringValue = ""
            self.infoVirtualenvTextField.isEnabled = false
        }
    }
    
    func getInfoVersion(executable: String) -> String? {
        let (_, error, status) = executeCommand(command: executable, args: ["--version"])
        if status == 0 {
            return error[0].replacingOccurrences(of: "Python ", with: "", options: .literal, range: nil)
        }
        return nil
    }
    
    func getInfoSystemDefault(executable: String) -> String? {
        let (output, _, status) = executeCommand(command: "/usr/bin/which", args: ["python"])
        if status == 0 {
            if executable == output[0] {
                return "yes"
            } else {
                return "no"
            }
        }
        return nil
    }
    
    func getInfoVirtualEnv(executable: String) -> String? {
        // TODO implement
        return "no"
    }
}

extension ViewControllerInterpreter: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.interpreterNames.count
    }

}

extension ViewControllerInterpreter: NSTableViewDelegate, NSTextFieldDelegate {

    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text: String = ""
        var cellIdentifier: String = ""

        let interpreterName = interpreterNames[row]
        
        // Based on the column where the cell will display, it sets the cell identifier and text.
        if tableColumn == tableView.tableColumns[0] {
            text = interpreterName
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // Gets a cell view, creates or reuse cell with identifier, then fills it with the information provided in the previous step and return it.
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            
            if text == userDefaults.string(forKey: UserDefaultStruct.interpreterStockName)! {
                cell.textField?.isEditable = false
            } else {
                cell.textField?.isEditable = true
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        // Update the values shown on the right side.
        self.updateProperties()
        
        // A change of selection can also be the first step of an editing session. Watch out for this.
        let selectedRow = self.tableView.selectedRow
        
        // When no row is selected, the index is -1.
        if (selectedRow > -1) {
            let selectedCell = self.tableView.view(atColumn: self.tableView.column(withIdentifier: CellIdentifiers.NameCell),
                                                   row: selectedRow,
                                                   makeIfNecessary: true) as! NSTableCellView
            
            // Get the textField to detect and add it the delegate.
            let textField = selectedCell.textField
            textField?.delegate = self
        }
    }

    override func controlTextDidBeginEditing(_ obj: Notification) {
        // Triggered once the user adds/removes the first character. Not when the textfield changes to editing mode.
        log.debug("controlTextDidBeginEditing")
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        // Triggered when in editing mode and textfield is deselected or enter is pressed (doesn't matter if text actually changed or not).
        log.debug("controlTextDidEndEditing")
    }

    override func controlTextDidChange(_ obj: Notification) {
        // Get the data every time the user writes a character. But not when using the arrow keys.
        log.debug("controlTextDidChange")
    }
}
