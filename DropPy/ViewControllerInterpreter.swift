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
    var selectedRow: Int = -1  // initialized value corresponding to state "no row selected"
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.reloadSettings()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var executableTextField: NSTextField!
    
    @IBAction func onExecutableTextField(_ sender: Any) {
        let selectedInterpreterName = self.interpreterNames[self.selectedRow]
        let newExecutable = self.executableTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // String must not be empty.
        if newExecutable.characters.count == 0 {
            self.errorAlert(title: "Invalid executable", explanation: "You have to specify an executable.\n\nChanges were not saved.")
            return
        }
        
        // String must not contain spaces, that's what the argument textfield is for.
        if newExecutable.range(of:" ") != nil {
            self.errorAlert(title: "Invalid executable", explanation: "The path to the executable must not contain spaces. Use the \"arguments\" textbox instead.\n\nChanges were not saved.")
            return
        }
        
        // String must start with "/".
        if !newExecutable.hasPrefix("/") {
            self.errorAlert(title: "Invalid executable", explanation: "The path to the executable must start with \"/\". Relative paths are not supported.\n\nChanges were not saved.")
            return
        }
        
        // String must end with "python" (case sensitive).
        if !(newExecutable.hasSuffix("python") || newExecutable.hasSuffix("python3")) {
            self.errorAlert(title: "Invalid executable", explanation: "The path must point to a executable named \"python\" or \"python3\".\n\nChanges were not saved.")
            return
        }
        
        // File must exist.
        if !fileExists(path: newExecutable) {
            self.errorAlert(title: "Invalid executable", explanation: "File not found. Check executable path.\n\nChanges were not saved.")
            return
        }
        
        self.editExecutable(interpreterName: selectedInterpreterName, newExecutable: newExecutable)
    }
    
    @IBOutlet weak var argumentsTextField: NSTextField!
    
    @IBAction func onArgumentsTextField(_ sender: Any) {
        let selectedInterpreterName = self.interpreterNames[self.selectedRow]
        let newArguments = self.argumentsTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        self.editArguments(interpreterName: selectedInterpreterName, newArguments: newArguments)
    }
    
    @IBOutlet weak var infoVersionTextField: NSTextField!
    
    @IBOutlet weak var infoSystemDefaultTextField: NSTextField!
    
    @IBOutlet weak var infoVirtualenvTextField: NSTextField!
    
    @IBAction func onPlusButton(_ sender: Any) {
        self.addInterpreter()
        self.reloadSettings()
        self.tableView.reloadData()
    }
    
    @IBAction func onMinusButton(_ sender: Any) {
        if (self.selectedRow > -1) {
            let selectedInterpreterName: String = self.interpreterNames[self.selectedRow]
            if selectedInterpreterName == userDefaults.string(forKey: UserDefaultStruct.interpreterStockName) {
                self.errorAlert(title: "Unable to remove", explanation: "The interpreter that comes with macOS cannot be removed.")
            } else {
                self.deleteInterpreterAlert(title: "Are you sure you want to remove this interpreter?",
                                            explanation: "There is no undo. You'll have to manually add it again.",
                                            trueButtonText: "Remove interpreter",
                                            selectedInterpreterName: selectedInterpreterName)
            }
        }
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/settings/interpreter"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for Interpreter openened.")
        }
    }
    
    func reloadSettings() {
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
        let (output, error, status) = executeCommand(command: executable, args: ["--version"])
        if status == 0 {
            // Python 2 returns version string in stderr, but Python 3 in stdout; exit code is always 0 though.
            if output[0] != "" {
                return output[0].replacingOccurrences(of: "Python ", with: "", options: .literal, range: nil)
            }
            if error[0] != "" {
                return error[0].replacingOccurrences(of: "Python ", with: "", options: .literal, range: nil)
            }
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
        // Check for existence of "activate" script in same folder as executable.
        var fileURL: URL = URL(fileURLWithPath: executable)
        fileURL = fileURL.deletingLastPathComponent()
        fileURL.appendPathComponent("activate")

        if fileExists(path: fileURL.path) == true {
            return "yes"
        } else {
            return "no"
        }
    }
    
    func editExecutable(interpreterName: String, newExecutable: String) {
        let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict[interpreterName]?["executable"] = newExecutable
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
    }
    
    func editArguments(interpreterName: String, newArguments: String) {
        let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict[interpreterName]?["arguments"] = newArguments
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
    }
    
    func renameInterpreter(oldName: String, newName: String) {
        let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict[newName] = ["executable": oldInterpreterDict[oldName]!["executable"]!,
                                       "arguments": oldInterpreterDict[oldName]!["arguments"]!]
        newInterpreterDict.removeValue(forKey: oldName)
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
    }
    
    func addInterpreter() {
        let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        
        let defaultExecutable: String = oldInterpreterDict[userDefaults.string(forKey: UserDefaultStruct.interpreterStockName)!]!["executable"]!
        let defaultArguments: String = oldInterpreterDict[userDefaults.string(forKey: UserDefaultStruct.interpreterStockName)!]!["arguments"]!
        
        var newInterpreterName: String = "New Interpreter"
        if self.interpreterNames.contains(newInterpreterName) {
            var occurrances: Int = 1
            for interpreter in self.interpreterNames {
                if interpreter.hasPrefix("New Interpreter") {
                    occurrances += 1
                }
            }
            newInterpreterName = "New Interpreter \(occurrances)"
        }
        
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict[newInterpreterName] = ["executable": defaultExecutable,
                                                  "arguments": defaultArguments]
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
    }
    
    func removeInterpreter(name: String) {
        let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict.removeValue(forKey: name)
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
    }
    
    func errorAlert(title: String, explanation: String) {
        let myAlert = NSAlert()
        myAlert.showsHelp = false
        myAlert.messageText = title
        myAlert.informativeText = explanation
        myAlert.addButton(withTitle: "Ok")
        myAlert.layout()
        myAlert.alertStyle = NSAlertStyle.warning
        myAlert.icon = NSImage(named: "error")
        myAlert.beginSheetModal(for: NSApplication.shared().mainWindow!)
    }

    func deleteInterpreterAlert(title: String, explanation: String, trueButtonText: String, selectedInterpreterName: String) {
        let myAlert = NSAlert()
        myAlert.showsHelp = false
        myAlert.messageText = title
        myAlert.informativeText = explanation
        myAlert.addButton(withTitle: trueButtonText)
        myAlert.addButton(withTitle: "Cancel")
        myAlert.layout()
        myAlert.alertStyle = NSAlertStyle.critical
        myAlert.icon = NSImage(named: "alert")
        
        myAlert.beginSheetModal(for: NSApplication.shared().mainWindow!, completionHandler: { [unowned self] (returnCode) -> Void in
            if returnCode == NSAlertFirstButtonReturn {
                self.removeInterpreter(name: selectedInterpreterName)
                self.reloadSettings()
                self.tableView.reloadData()
            }
        })
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
        self.selectedRow = self.tableView.selectedRow
        
        // When no row is selected, the index is -1.
        if (self.selectedRow > -1) {
            let selectedCell = self.tableView.view(atColumn: self.tableView.column(withIdentifier: CellIdentifiers.NameCell),
                                                   row: self.selectedRow,
                                                   makeIfNecessary: true) as! NSTableCellView
            
            // Get the textField to detect and add it the delegate.
            let textField = selectedCell.textField
            textField?.delegate = self
        }
    }

    override func controlTextDidBeginEditing(_ obj: Notification) {
        // Triggered once the user adds/removes the first character. Not when the textfield changes to editing mode.
        
        // Does not matter, I just want to save the new value.
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        // Triggered when in editing mode and textfield is deselected or enter is pressed (doesn't matter if text actually changed or not).

        if let editedTextField: NSTextField = obj.object as? NSTextField {

            let oldName: String = self.interpreterNames[self.selectedRow]
            let newName: String = editedTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip everything if the item was not renamed.
            if oldName == newName {
                return
            }

            // Empty value not allowed, reset to previous value.
            if editedTextField.stringValue.characters.count == 0 {
                self.errorAlert(title: "Interpreter name can not be empty", explanation: "The value will be reset.")
                editedTextField.stringValue = oldName
                return
            }

            // Already existing value not allowed, reset to previous value.
            var otherInterpreterNames = self.interpreterNames
            otherInterpreterNames.remove(at: self.selectedRow)
            if otherInterpreterNames.contains(editedTextField.stringValue) {
                self.errorAlert(title: "Interpreter name already in use", explanation: "The value will be reset.")
                editedTextField.stringValue = oldName
                return
            }

            // Everything ok.
            self.renameInterpreter(oldName: oldName, newName: newName)
            self.reloadSettings()
            self.tableView.reloadData()
        }
    }

    override func controlTextDidChange(_ obj: Notification) {
        // Get the data every time the user writes a character. But not when using the arrow keys.

        // Not necessary to use this to provide live behavior.
        // To use the new value in the main window the user expects to have to deselect the textfield.
    }
}
