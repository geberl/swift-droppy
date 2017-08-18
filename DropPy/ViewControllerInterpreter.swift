//
//  ViewControllerInterpreter.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

// Tutorial for tableView:
// https://www.raywenderlich.com/143828/macos-nstableview-tutorial

// Maybe also useful for getting editing to work:
// https://stackoverflow.com/questions/28281045/view-based-nstableview-editing

import Cocoa

class ViewControllerInterpreter: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    var mySampleInterpreters: [String] = []
    
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
        
        self.mySampleInterpreters = ["macOS bundled", "Homebrew 2.7", "Homebrew 3.5", "My PDF env"]
        
    }
    
    func updateStatus() {
        let itemsSelectedd = tableView.numberOfSelectedRows
        log.debug("b \(itemsSelectedd)")
        
        let itemsSelectedc = tableView.selectedRowIndexes.first
        log.debug("c \(String(describing: itemsSelectedc))")  // is optinal, may therfor be nil
    }

}

extension ViewControllerInterpreter: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.mySampleInterpreters.count
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        log.debug("edit")
    }
    
}

extension ViewControllerInterpreter: NSTableViewDelegate {

    fileprivate enum CellIdentifiers {
        static let NameCell = "NameCellID"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        var text: String = ""
        var cellIdentifier: String = ""

        let item = mySampleInterpreters[row]
        
        // Based on the column where the cell will display, it sets the cell identifier and text.
        if tableColumn == tableView.tableColumns[0] {
            text = item
            cellIdentifier = CellIdentifiers.NameCell
        }
        
        // Gets a cell view, creates or reuse cell with identifier, then fills it with the information provided in the previous step and return it.
        if let cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            
            if text == "macOS bundled" {
                cell.textField?.isEditable = false
            } else {
                cell.textField?.isEditable = true
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateStatus()
    }
}
