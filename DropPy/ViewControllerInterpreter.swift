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
import os.log


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
    
    @IBAction func onExecutableTextField(_ sender: NSTextField) {
        let selectedInterpreterName = self.interpreterNames[self.selectedRow]
        var newExecutable = self.executableTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)  // silently trim when getting the value
        self.executableTextField.stringValue = newExecutable  // write trimmed string back to input

        // String must not be empty.
        if newExecutable.count == 0 {
            self.errorAlert(title: "Invalid executable", explanation: "You have to specify an executable.")
        }
        // String must start with "/".
        else if !newExecutable.hasPrefix("/") {
            self.errorAlert(title: "Invalid executable", explanation: "The path to the executable has to start with \"/\". Relative paths are not supported.")
        }
        // String must not contain arguments.
        else if newExecutable.range(of:" ") != nil {
            // TODO this solution does not catch '/abc/def/python -B -c -R "/abc/def/ghi"', however the later checks fail for this.

            // Example starting out with /Users/guenther/My Virtual Env/bin/python -B -c -R
            var executablePathArray: Array = newExecutable.components(separatedBy: "/")  // [Users, guenther, My Virtual Env, bin, python -B -c -R]
            let executableLastPart: String = executablePathArray[executablePathArray.count - 1]  // python -B -c -R
            if executableLastPart.range(of:" ") != nil {
                var executableAndArguments: Array = executableLastPart.components(separatedBy: " ")  // [python, -B, -c, -R]
                executablePathArray.remove(at: executablePathArray.count - 1)  // [Users, guenther, My Virtual Env, bin]
                executablePathArray.append(executableAndArguments[0])  // [Users, guenther, My Virtual Env, bin, python]
                newExecutable = executablePathArray.joined(separator: "/")  // /Users/guenther/My Virtual Env/bin/python
                executableAndArguments.remove(at: 0)  // [-B, -c, -R]
                var newArguments: String = executableAndArguments.joined(separator: " ")  // -B -c -R

                self.executableTextField.stringValue = newExecutable

                let presentArguments = self.argumentsTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)  // silently trim when getting the value
                if presentArguments.count > 0 {
                    newArguments = presentArguments + " " + newArguments
                }
                self.argumentsTextField.stringValue = newArguments
                self.editArguments(interpreterName: selectedInterpreterName, newArguments: newArguments)
                
                self.errorAlert(title: "Invalid executable", explanation: "The path to the executable must not contain arguments.\n\nYour inputs were adjusted, please check.")
            }
        }
        // File must exist.
        else if !isFile(path: newExecutable) {
            self.errorAlert(title: "Invalid executable", explanation: "File not found. Check executable path.")
        }
        // String must end with "python" (case sensitive on purpose).
        else if !(newExecutable.hasSuffix("python") || newExecutable.hasSuffix("python2") || newExecutable.hasSuffix("python3")) {
            self.errorAlert(title: "Invalid executable", explanation: "The path usually points to an executable named \"python\", \"python2\" or \"python3\".")
        }

        // Save value anyways for better user experience.
        self.editExecutable(interpreterName: selectedInterpreterName, newExecutable: newExecutable)
        
        // Refresh info values
        self.updateProperties()
    }
    
    @IBOutlet weak var argumentsTextField: NSTextField!
    
    @IBAction func onArgumentsTextField(_ sender: Any) {
        let selectedInterpreterName = self.interpreterNames[self.selectedRow]
        let newArguments = self.argumentsTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)  // silently trim when getting the value
        self.argumentsTextField.stringValue = newArguments  // write trimmed string back to input
        self.editArguments(interpreterName: selectedInterpreterName, newArguments: newArguments)
    }
    
    @IBOutlet weak var infoVersionTextField: NSTextField!
    
    @IBOutlet weak var infoSystemDefaultTextField: NSTextField!
    
    @IBOutlet weak var infoVirtualenvTextField: NSTextField!
    
    @IBAction func onPlusButton(_ sender: Any) {
        self.addInterpreter()
    }
    
    @IBAction func onMinusButton(_ sender: Any) {
        if (self.selectedRow > -1) {
            let selectedInterpreterName: String = self.interpreterNames[self.selectedRow]
            if selectedInterpreterName == AppState.interpreterStockName {
                self.errorAlert(title: "Unable to remove",
                                explanation: "The interpreter that comes with macOS cannot be removed.")
            } else {
                self.confirmInterpreterAlert()
            }
        }
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        openWebsite(webUrl: droppyappUrls.prefsInterpreter)
    }
    
    func reloadSettings() {
        if let interpreterDict: Dictionary = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) {
            self.interpreterNames = Array(interpreterDict.keys).sorted()
        }
    }
    
    func confirmInterpreterAlert() {
        let criticalAlert = NSAlert()
        criticalAlert.showsHelp = false
        criticalAlert.messageText = "Are you sure you want to remove this interpreter?"
        criticalAlert.informativeText = "There is no undo. You'll have to manually add it again."
        criticalAlert.addButton(withTitle: "Remove interpreter")
        criticalAlert.addButton(withTitle: "Cancel")
        criticalAlert.layout()
        criticalAlert.alertStyle = NSAlert.Style.critical
        criticalAlert.icon = NSImage(named: NSImage.Name(rawValue: "alert"))
        criticalAlert.beginSheetModal(for: NSApplication.shared.mainWindow!,
                                      completionHandler: self.removeSelectedInterpreter)
    }
    
    func updateProperties() {
        if let selectedInterpreterIndex = tableView.selectedRowIndexes.first {
            os_log("Selected interpreter item %d.", log: logUi, type: .debug, selectedInterpreterIndex)
            
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
                
                if selectedInterpreterName == AppState.interpreterStockName {
                    self.argumentsTextField.isEditable = false
                    self.executableTextField.isEditable = false
                } else {
                    self.argumentsTextField.isEditable = true
                    self.executableTextField.isEditable = true
                }
            }
        } else {
            os_log("No interpreter is selected.", log: logUi, type: .debug)

            self.executableTextField.stringValue = ""
            self.argumentsTextField.stringValue = ""
            
            self.executableTextField.isEditable = false
            self.argumentsTextField.isEditable = false
            
            self.executableTextField.isSelectable = false
            self.argumentsTextField.isSelectable = false
            
            self.infoVersionTextField.stringValue = ""
            self.infoVersionTextField.isEnabled = false
            
            self.infoSystemDefaultTextField.stringValue = ""
            self.infoSystemDefaultTextField.isEnabled = false
            
            self.infoVirtualenvTextField.stringValue = ""
            self.infoVirtualenvTextField.isEnabled = false
        }
    }
    
    func getInfoVersion(executable: String) -> String? {
        
        // Executable must not be empty.
        if executable.count == 0 {
            return "no executable set"
        }
            
        // Executable must start with "/".
        if !executable.hasPrefix("/") {
            return "no absolute path set"
        }

        // Executable must be a known "python" executable (case sensitive).
        if !(executable.hasSuffix("python") || executable.hasSuffix("python2") || executable.hasSuffix("python3")) {
            return "not supported"
        }

        // File must exist.
        if !isFile(path: executable) {
            return "executable not found"

        }

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
        
        // Check for existance of interpreter executable.
        if isFile(path: executable) {
            
            // Check for existence of "activate" script in same folder as executable.
            var fileURL: URL = URL(fileURLWithPath: executable)
            fileURL = fileURL.deletingLastPathComponent()
            fileURL.appendPathComponent("activate")

            if isFile(path: fileURL.path) == true {
                return "yes"
            } else {
                return "no"
            }
            
        }
        return nil
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
        
        var defaultExecutable: String = ""
        var defaultArguments: String = ""
        if oldInterpreterDict[AppState.interpreterStockName] != nil {
            defaultExecutable = oldInterpreterDict[AppState.interpreterStockName]!["executable"]!
            defaultArguments = oldInterpreterDict[AppState.interpreterStockName]!["arguments"]!
        }
        
        var newInterpreterName: String = "New Interpreter"
        var nextSuffix: Int = 2  // on macOS the next item is called "New Interpreter 2", not "New Interpreter 1".
        while self.interpreterNames.contains(newInterpreterName) {
            newInterpreterName = "New Interpreter \(nextSuffix)"
            nextSuffix += 1
        }
        
        var newInterpreterDict = oldInterpreterDict
        newInterpreterDict[newInterpreterName] = ["executable": defaultExecutable,
                                                  "arguments": defaultArguments]
        userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
        
        self.reloadSettings()
        self.tableView.reloadData()
    }
    
    func removeSelectedInterpreter(userChoice: NSApplication.ModalResponse) {
        if userChoice == NSApplication.ModalResponse.alertFirstButtonReturn {
            let oldInterpreterDict: Dictionary<String, Dictionary<String, String>> = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) as! Dictionary<String, Dictionary<String, String>>
            var newInterpreterDict = oldInterpreterDict
            newInterpreterDict.removeValue(forKey: self.interpreterNames[self.selectedRow])
            userDefaults.set(newInterpreterDict, forKey: UserDefaultStruct.interpreters)
            
            self.reloadSettings()
            self.tableView.reloadData()
            self.updateProperties()
        }
    }
    
    func errorAlert(title: String, explanation: String) {
        let errorAlert = NSAlert()
        errorAlert.showsHelp = false
        errorAlert.messageText = title
        errorAlert.informativeText = explanation
        errorAlert.addButton(withTitle: "Ok")
        errorAlert.layout()
        errorAlert.alertStyle = NSAlert.Style.warning
        errorAlert.icon = NSImage(named: NSImage.Name(rawValue: "error"))
        errorAlert.beginSheetModal(for: NSApplication.shared.mainWindow!)
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
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            
            if text == AppState.interpreterStockName {
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
        os_log("Table selection did change. Selected row now: %d.", log: logUi, type: .debug, self.selectedRow)

        // When no row is selected, the index is -1.
        if (self.selectedRow > -1) {
            let selectedCell = self.tableView.view(atColumn: 0,
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
            if editedTextField.stringValue.count == 0 {
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
