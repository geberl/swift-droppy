//
//  WindowControllerMain.swift
//  DropPy
//
//  Created by Günther Eberl on 04.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON


class WindowControllerMain: NSWindowController {
    
    let userDefaults = UserDefaults.standard
    
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

    lazy var editorWindowController: WindowControllerEditor  = {
        let wcSB = NSStoryboard(name: "Editor", bundle: Bundle.main)
        return wcSB.instantiateInitialController() as! WindowControllerEditor
    }()

    override func windowWillLoad() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.refreshToolbarDropdown(notification:)),
                                               name: Notification.Name("workflowsChanged"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.actionOnEmptyWorkflow(notification:)),
                                               name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(WindowControllerMain.unupportedType(notification:)),
                                               name: Notification.Name("unsupportedType"), object: nil)
    }

    func refreshToolbarDropdown(notification: Notification){
        log.debug("Toolbar Dropdown refreshing")
        
        // Start fresh with an empty dropdown
        ToolbarDropdown.removeAllItems()
        
        // Add the empty string placeholder item to the dropdown
        let placeholderMenuItem = NSMenuItem()
        placeholderMenuItem.title = ""
        placeholderMenuItem.target = self
        placeholderMenuItem.action = #selector(selectEmptyWorkflow)
        ToolbarDropdown.addItem(placeholderMenuItem)
        
        // Sort Workflow names alphabetically
        let allWorkflowNames:[String] = NSDictionary(dictionary: Workflows.workflows).allKeys as! [String]
        let sortedWorkflowNames = allWorkflowNames.sorted(){ $0 < $1 }

        // Add Workflows to the dropdown in that order
        for name:String in sortedWorkflowNames {
            let newMenuItem = NSMenuItem()
            newMenuItem.title = name
            newMenuItem.target = self
            newMenuItem.action = #selector(workflowSelectionChanged)
            ToolbarDropdown.addItem(newMenuItem)
        }
    }
    
    func selectEmptyWorkflow() {
        Workflows.activeJsonFile = ""
        Workflows.activeInterpreterName = ""
        Workflows.activeLogoFilePath = ""
        Workflows.activeName = ""
        Workflows.activeAccepts = []

        NotificationCenter.default.post(name: Notification.Name("workflowSelectionChanged"), object: nil)
    }
    
    func workflowSelectionChanged() {
        // User changed highlight in the Workflows dropdown, now update the global Workflows object (in AppDelegate)

        // Name from dropdown
        Workflows.activeName = self.getSelectedWorkflow()
        
        // Rest from Workflows.workflows object
        for (name, _):(String, Dictionary<String, Any>) in Workflows.workflows {
            if name == Workflows.activeName {
                let workflowJsonFile: String = Workflows.workflows[name]?["file"] as! String
                log.debug("Workflow definition '\(workflowJsonFile)' is now active.")
                Workflows.activeJsonFile = workflowJsonFile
                
                let workflowLogoFile: String = Workflows.workflows[name]?["image"] as! String
                log.debug("Workflow logo '\(workflowLogoFile)' is now active.")
                
                let workspacePath: String = self.userDefaults.string(forKey: UserDefaultStruct.workspacePath)!
                Workflows.activeLogoFilePath = "\(workspacePath)/Workflows/\(workflowLogoFile)"
                
                let workflowAccepts: Array = Workflows.workflows[name]!["accepts"] as! Array<String>
                log.debug("Workflow accepts '\(workflowAccepts)' for drag & drop.")
                Workflows.activeAccepts = workflowAccepts
                
                let workflowInterpreterName: String = Workflows.workflows[name]?["interpreterName"] as! String
                log.debug("Workflow will use the interpreter named '\(workflowInterpreterName)'.")
                Workflows.activeInterpreterName = workflowInterpreterName

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
        
        let workspacePath: String = self.userDefaults.string(forKey: UserDefaultStruct.workspacePath)!
        NSWorkspace.shared().selectFile("\(workspacePath)/Workflows/\(Workflows.activeJsonFile)", inFileViewerRootedAtPath: "\(workspacePath)")
    }
    
    func editWorkflow() {
        log.debug("Toolbar Action: Edit")
        
        if Workflows.activeName == "" {
            NotificationCenter.default.post(name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
        } else {
            let workspacePath: String = self.userDefaults.string(forKey: UserDefaultStruct.workspacePath)!
            let workflowFile: String = "\(workspacePath)/Workflows/\(Workflows.activeJsonFile)"
            
            if let editorForWorkflows: String = self.userDefaults.string(forKey: UserDefaultStruct.editorForWorkflows) {
                
                if editorForWorkflows == "Internal Workflow editor" {
                    // TODO: Implement internal Workflow editor and have it open from here.
                    log.debug("Open internal Workflow editor now")
                    
                } else if editorForWorkflows == "Internal text editor" {
                    self.editorWindowController.showWindow(self)
                    
                    let pathDict:[String: String] = ["path": workflowFile]
                    NotificationCenter.default.post(name: Notification.Name("loadFileInEditor"), object: nil, userInfo: pathDict)

                } else if editorForWorkflows == "External text editor" {
                    // This way of launching an external program hopefully is ok with the app sandbox, Process() may not be.
                    // However this is why passing custom parameters to the external editor is currently not possible.
                    let editorApp: String = self.userDefaults.string(forKey: UserDefaultStruct.editorAppPath)!
                    NSWorkspace.shared().openFile(workflowFile, withApplication: editorApp)
                }
            }
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
            let workflowInterpreterName: String = "default"
        
            // Create SwiftyJSON object
            let jsonObject: JSON = ["name": workflowName,
                                    "author": "Your name here",
                                    "description": "A short description what this Workflow does. Currently not accessed by DropPy. For now just for your own documentation purposes.",
                                    "image": "",
                                    "interpreterName": workflowInterpreterName,
                                    "accepts": ["file", "url"],
                                    "tasks": []]
        
            // Convert SwiftyJSON object to string
            let jsonString = jsonObject.description
        
            // Setup objects needed for directory and file access
            let workspacePath: String = self.userDefaults.string(forKey: UserDefaultStruct.workspacePath)!
            let filePath: URL = NSURL.fileURL(withPath: "\(workspacePath)/Workflows/\(workflowFileName)")
        
            // Write json string to file, this overwrites a preexisting file here
            try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)

            // Update global Workflow object
            Workflows.activeInterpreterName = workflowInterpreterName
            Workflows.activeJsonFile = workflowFileName
            Workflows.activeName = workflowName
            Workflows.activeAccepts = ["file", "url"]
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
    
    func unupportedType(notification: Notification) {
        // TODO support more types
        let alert = NSAlert()
        alert.messageText = "Error: Unsupported Type"
        alert.informativeText = "The item you dropped doesn't support the types of your selected Workflow: \(Workflows.activeAccepts)\n\nDropPy itself currently only supports the 'filename' type."
        alert.icon = NSImage(named: "LogoError")
        alert.runModal()
    }
}
