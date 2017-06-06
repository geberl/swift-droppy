//
//  WindowController.swift
//  DropPy
//
//  Created by Günther Eberl on 04.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON



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
                                               name: Notification.Name("workflowsChanged"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowController.actionOnEmptyWorkflow(notification:)),
                                               name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
    }
    
    func refreshToolbarDropdown(notification: Notification){
        log.debug("Toolbar Dropdown refreshing")
        
        ToolbarDropdown.removeAllItems()
        
        let placeholderMenuItem = NSMenuItem()
        placeholderMenuItem.title = ""
        placeholderMenuItem.target = self
        placeholderMenuItem.action = #selector(selectEmptyWorkflow)
        ToolbarDropdown.addItem(placeholderMenuItem)
        
        // TODO add workflows in alphabetical order of their names
        
        for (key, _):(String, Dictionary<String, String>) in Workflows.workflows {
            let newMenuItem = NSMenuItem()
            newMenuItem.title = key
            newMenuItem.target = self
            newMenuItem.action = #selector(workflowSelectionChanged)
            ToolbarDropdown.addItem(newMenuItem)
        }
    }
    
    func selectEmptyWorkflow() {
        Workflows.activeJsonFile = ""
        Workflows.activeLogoFilePath = ""
        Workflows.activeName = ""

        NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
    }
    
    func workflowSelectionChanged() {
        // User changed highlight in the Workflows dropdown, now update the global Workflows object (in AppDelegate)

        // Name
        Workflows.activeName = self.getSelectedWorkflow()
        
        // Json file
        for (name, _):(String, Dictionary<String, String>) in Workflows.workflows {
            if name == Workflows.activeName {
                let workflowJsonFile: String = (Workflows.workflows[name]?["file"]!)!
                log.debug("Workflow definition '\(workflowJsonFile)' is now active")
                Workflows.activeJsonFile = workflowJsonFile
                break
            }
        }
        
        // Logo image file
        for (name, _):(String, Dictionary<String, String>) in Workflows.workflows {
            if name == Workflows.activeName {
                let workflowLogoFile: String = (Workflows.workflows[name]?["image"]!)!
                log.debug("Workflow logo '\(workflowLogoFile)' is now active")
                Workflows.activeLogoFilePath = "/Users/guenther/\(Settings.baseFolder)Workflows/\(workflowLogoFile)"
                break
            }
        }
        
        // Send out a notification (to change the logo in ViewController)
        NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
    }
    
    func getSelectedWorkflow() -> String {
        if (ToolbarDropdown.highlightedItem != nil) {
            // User has already clicked on a workflow in the dropdown
            return ToolbarDropdown.highlightedItem!.title
        }
        else {
            // User has not yet clicked on a workflow, the one that was first added is still showing (=the empty one)
            return ToolbarDropdown.item(at: 0)!.title
        }
    }
    
    func openFinder() {
        log.debug("Toolbar Action: Open")
        NSWorkspace.shared().selectFile("/Users/guenther/\(Settings.baseFolder)Workflows/\(Workflows.activeJsonFile)",
            inFileViewerRootedAtPath: "/Users/guenther/")
    }
    
    func editWorkflow() {
        log.debug("Toolbar Action: Edit")
        if Workflows.activeName == "" {
            NotificationCenter.default.post(name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
        } else {
            NSWorkspace.shared().openFile("/Users/guenther/\(Settings.baseFolder)Workflows/\(Workflows.activeJsonFile)",
                withApplication: "Visual Studio Code")
        }
    }
    
    func addWorkflow() {
        log.debug("Toolbar Action: Add")
        
       do {
            // Get the current datetime as a string
            let stringFromDate = Date().iso8601
        
            // Determine Workflow name (for inside the JSON file) and the JSON file's filename.
            let workflowName: String = "New Workflow \(stringFromDate)"
            let workflowFileName: String = "new_workflow_\(stringFromDate).json"
        
            // Create SwiftyJSON object
            let jsonObject: JSON = ["name": workflowName,
                                    "author": "Your name here",
                                    "description": "A short description what this Workflow does. Currently not accessed by DropPy. For now just for your own documentation purposes.",
                                    "image": "",
                                    "executable": "Python 3",
                                    "tasks": []]
        
            // Convert SwiftyJSON object to string
            let jsonString = jsonObject.description
        
            // Setup objects needed for directory and file access
            let userDir: URL = FileManager.default.homeDirectoryForCurrentUser
            let filePath: URL = userDir.appendingPathComponent("\(Settings.baseFolder)Workflows/\(workflowFileName)")
        
            print("\(Settings.baseFolder)/Workflows/\(workflowFileName)")
        
            // Write json string to file, this overwrites a preexisting file here
            try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)

        
            // Update global Workflow object
            Workflows.activeJsonFile = workflowFileName // TODO this is wrong
            Workflows.activeName = workflowName
            Workflows.activeLogoFilePath = ""
        
            // Open new file in editor
            self.editWorkflow()
        } catch {
            log.error(error.localizedDescription)
        }
    }
    
    func actionOnEmptyWorkflow(notification: Notification) {
        let alert = NSAlert()
        alert.messageText = "Error: No Workflow selected"
        alert.informativeText = "You can't perform this action when no Workflow is selected.\n\nSelect a Workflow from the dropdown and try again."
        alert.icon = NSImage(named: "LogoError")
        alert.runModal()
    }
}
