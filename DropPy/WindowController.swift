//
//  WindowController.swift
//  DropPy
//
//  Created by Günther Eberl on 04.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa



class WindowController: NSWindowController {
    
    @IBOutlet weak var ToolbarDropdown: NSMenu!
    
    @IBAction func ToolbarActions(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.editWorkflow()
        }
        else if sender.selectedSegment == 1 {
            self.openFinder()
        }
        else if sender.selectedSegment == 2 {
            self.addWorkflow()
        }
    }

    override func windowWillLoad() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowController.refreshToolbarDropdown(notification:)),
                                               name: Notification.Name("appWillBecomeActive"), object: nil)
    }
    
    func refreshToolbarDropdown(notification: Notification){
        log.debug("Toolbar Dropdown refreshing")
        
        ToolbarDropdown.removeAllItems()
        
        let aboutMenuItem = NSMenuItem()
        aboutMenuItem.title = "About"
        aboutMenuItem.target = self
        ToolbarDropdown.addItem(aboutMenuItem)
        
        let anotherMenuItem = NSMenuItem()
        anotherMenuItem.title = "Another"
        anotherMenuItem.target = self
        ToolbarDropdown.addItem(anotherMenuItem)
    }
    
    func getSelectedWorkflow() -> String {
        if (ToolbarDropdown.highlightedItem != nil) {
            // User has already clicked on a workflow in the dropdown
            return ToolbarDropdown.highlightedItem!.title
        }
        else {
            if ToolbarDropdown.numberOfItems > 0 {
                // User has not yet clicked on a workflow, the one that was first added is still showing
                return ToolbarDropdown.item(at: 0)!.title
            }
            else {
                // Special case empty dropdown, no workflows available
                // TODO disallow workflows named "" when adding them, pop up error message
                return ""
            }
        }
    }
    
    func openFinder() {
        log.debug("Toolbar Action: Open")
        print(getSelectedWorkflow())
        NSWorkspace.shared().selectFile("/Users/guenther/Downloads/trainspotting 2 (eng-2017).srt",
                                        inFileViewerRootedAtPath: "/Users/guenther/Downloads")
    }
    
    func editWorkflow() {
        log.debug("Toolbar Action: Edit")
        print(getSelectedWorkflow())
        NSWorkspace.shared().openFile("/Users/guenther/Downloads/trainspotting 2 (eng-2017).srt",
                                      withApplication: "Visual Studio Code")
    }
    
    func addWorkflow() {
        log.debug("Toolbar Action: Add")
    }
}
