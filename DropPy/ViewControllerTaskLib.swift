//
//  ViewControllerTaskLib.swift
//  DropPy
//
//  Created by Günther Eberl on 24.02.18.
//  Copyright © 2018 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


// Tutorial:
// https://www.raywenderlich.com/123463/nsoutlineview-macos-tutorial


class ViewControllerTaskLib: NSViewController {
    
    @IBOutlet weak var taskOutlineView: NSOutlineView!
    
    var taskCategories = [ObjectTaskCategory]()

    override func viewDidLoad() {
        super.viewDidLoad()
        os_log("ViewControllerTaskLib viewDidLoad", log: logGeneral)
        
        self.loadTasks()
        self.taskOutlineView.reloadItem(nil, reloadChildren: true)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        os_log("ViewControllerTaskLib viewWillAppear", log: logGeneral)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerTaskLib.disableRemoveButton),
                                               name: .clearSelection, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerTaskLib.enableRemoveButton),
                                               name: .selectTask, object: nil)
    }
    
    func loadTasks() {
        // TODO actually traverse the Tasks directory and parse the task.py files.
        
        let taskCatOne = ObjectTaskCategory(name: "Image")
        //taskCatOne.children = taskCatOne.taskList()
        self.taskCategories.append(taskCatOne)
        
        let taskCatTwo = ObjectTaskCategory(name: "FileSystem")
        //taskCatTwo.taskList()
        self.taskCategories.append(taskCatTwo)
    }
    
    @IBAction func onReloadButton(_ sender: NSButton) {
        os_log("onReloadButton", log: logGeneral)
    }
    
    @IBAction func onAddButton(_ sender: NSButton) {
        os_log("onAddButton", log: logGeneral)
        NotificationCenter.default.post(name: .addTask, object: nil)
    }
    
    @IBAction func onRemoveButton(_ sender: NSButton) {
        os_log("onRemoveButton", log: logGeneral)
        NotificationCenter.default.post(name: .removeTask, object: nil)
        self.disableRemoveButton(nil)
    }
    
    @IBOutlet weak var removeButton: NSButton!
    
    @objc func disableRemoveButton(_ notification: Notification?) {
        os_log("disableRemoveButton", log: logGeneral)
        self.removeButton.isEnabled = false
    }
    
    @objc func enableRemoveButton(_ notification: Notification?) {
        os_log("enableRemoveButton", log: logGeneral)
        self.removeButton.isEnabled = true
    }
}


extension ViewControllerTaskLib: NSOutlineViewDataSource {
    // Functions are called for EVERY level of the hierarchy, so there are several cases to handle, one per level.
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // Number of children to display.
        if let taskCategory = item as? ObjectTaskCategory {
            return taskCategory.children.count
        }
        
        return self.taskCategories.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // Determine which child to show given a parent index.
        if let taskCategory = item as? ObjectTaskCategory {
            return taskCategory.children[index]
        }
        
        return self.taskCategories[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // Enable collapsing and expanding of items that have children.
        if let taskCategory = item as? ObjectTaskCategory {
            return taskCategory.children.count > 0
        }
        
        return false
    }
}


extension ViewControllerTaskLib: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let taskCategoryItem = item as? ObjectTaskCategory {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TaskCategoryCell"),
                                        owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = taskCategoryItem.name
                textField.sizeToFit()
            }
        } else if let taskItem = item as? ObjectTask {
            
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TaskCell"),
                                        owner: self) as? NSTableCellView
            
            if let textField = view?.textField {
                textField.stringValue = taskItem.name
                textField.sizeToFit()
            }
            
        }
        
        return view
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        os_log("outlineViewSelectionDidChange", log: logGeneral)
        
        guard let outlineView = notification.object as? NSOutlineView else {
            return
        }
        
        let selectedIndex = outlineView.selectedRow
        // Only displyed items are being counted, of all hierachy levels. Not displayed children are not counted.
        print(selectedIndex)
        
    }
}
