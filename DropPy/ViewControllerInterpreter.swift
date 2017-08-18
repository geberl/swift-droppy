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
        log.debug("Load interpreter settings now.")
        
        //self.interpreterNames = ["macOS bundled", "Homebrew 2.7", "Homebrew 3.5", "My PDF env"]
        
        if let interpreterDict: Dictionary = userDefaults.dictionary(forKey: UserDefaultStruct.interpreters) {
            log.debug("\(interpreterDict)")
            self.interpreterNames = Array(interpreterDict.keys)
        }
    }
    
    func updateProperties() {
        let itemsSelectedd = tableView.numberOfSelectedRows
        log.debug("b \(itemsSelectedd)")
        
        let itemsSelectedc = tableView.selectedRowIndexes.first
        log.debug("c \(String(describing: itemsSelectedc))")  // is optinal, may therfor be nil
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
                cell.textField?.isEditable = true
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
