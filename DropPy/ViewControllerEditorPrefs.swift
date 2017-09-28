//
//  ViewControllerEditorPrefs.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerEditorPrefs: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var editorIcon: EditorAppImageView!
    
    @IBOutlet weak var workflowEditor: NSPopUpButton!
    
    @IBOutlet weak var workflowEditorExternalTextEditor: NSMenuItem!
    
    @IBAction func onWorkflowEditor(_ sender: Any) {
        if (self.workflowEditor.selectedItem != nil) {
            self.userDefaults.set(self.workflowEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForWorkflows)
        } else {
            self.userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
        }
    }
    
    @IBOutlet weak var taskEditor: NSPopUpButton!
    
    @IBOutlet weak var taskEditorExternalTextEditor: NSMenuItem!
    
    @IBAction func onTaskEditor(_ sender: Any) {
        if (self.taskEditor.selectedItem != nil) {
            self.userDefaults.set(self.taskEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForTasks)
        } else {
            self.userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ViewControllerEditorPrefs.onEditorDropped(notification:)),
                                               name: Notification.Name("editorDropped"),
                                               object: nil)
    }
    
    @IBAction func onButtonClearEditor(_ sender: Any) {
        clearEditor()
    }
    
    func clearEditor() {
        self.editorIcon.appPath = ""
        self.editorIcon.iconPath = ""
        self.editorIcon.image = nil
        
        self.userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
        self.userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
        
        self.workflowEditor.selectItem(withTitle: UserDefaultStruct.editorForWorkflowsDefault)
        self.userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
        self.workflowEditorExternalTextEditor.isEnabled = false
        
        self.taskEditor.selectItem(withTitle: UserDefaultStruct.editorForTasksDefault)
        self.userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        self.taskEditorExternalTextEditor.isEnabled = false
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/preferences/editor"), NSWorkspace.shared().open(url) {
            os_log("Documentation site for Editor openened.", log: logUi, type: .debug)
        }
    }
    
    func onEditorDropped(notification: Notification) {
        self.workflowEditorExternalTextEditor.isEnabled = true
        self.taskEditorExternalTextEditor.isEnabled = true
        
        self.taskEditor.selectItem(withTitle: "External text editor")
        self.userDefaults.set(self.taskEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForTasks)
        
        self.workflowEditor.selectItem(withTitle: "External text editor")
        self.userDefaults.set(self.workflowEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForWorkflows)
    }

    func loadSettings() {
        if let editorAppPath: String = userDefaults.string(forKey: UserDefaultStruct.editorAppPath) {
            if isDir(path: editorAppPath) {
                self.editorIcon.appPath = editorAppPath
                if editorAppPath == "" {
                    self.workflowEditorExternalTextEditor.isEnabled = false
                    self.taskEditorExternalTextEditor.isEnabled = false
                } else {
                    self.workflowEditorExternalTextEditor.isEnabled = true
                    self.taskEditorExternalTextEditor.isEnabled = true
                }
            } else {
                self.clearEditor()
                return
            }
        }
        
        if let editorIconPath: String = userDefaults.string(forKey: UserDefaultStruct.editorIconPath) {
            if isFile(path: editorIconPath) {
                self.editorIcon.iconPath = editorIconPath
                self.editorIcon.setAppIcnsFile()
            } else {
                self.clearEditor()
                return
            }
        }

        if let workflowEditor: String = self.userDefaults.string(forKey: UserDefaultStruct.editorForWorkflows) {
            self.workflowEditor.selectItem(withTitle: workflowEditor)
        }

        if let taskEditor: String = self.userDefaults.string(forKey: UserDefaultStruct.editorForTasks) {
            self.taskEditor.selectItem(withTitle: taskEditor)
        }
    }
}

class EditorAppImageView: NSImageView {
    
    let userDefaults = UserDefaults.standard

    var appPath: String = ""
    var iconPath: String = ""

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [NSFilenamesPboardType])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // User has to drop an item from finder.
        if containsPasteboardType(sender: sender, pasteboardType: "public.file-url") {
            // User has to drop exactly 1 item.
            if countNumberOfItems(sender: sender, pasteboardType: "NSFilenamesPboardType") == 1 {
                // User's dropped item path must end with ".app".
                if getFileExtension(sender: sender) == "app" {
                    return .copy
                }
            }
        }
        return []
    }

    func containsPasteboardType(sender: NSDraggingInfo, pasteboardType: String) -> Bool {
        let pasteboard = sender.draggingPasteboard()
        
        if pasteboard.types?.contains(pasteboardType) == true {
            return true
        } else {
            os_log("Type doesn't contain '%@'.", log: logUi, type: .debug, pasteboardType)
            return false
        }
    }
    
    func countNumberOfItems(sender: NSDraggingInfo, pasteboardType: String) -> Int {
        if let board = sender.draggingPasteboard().propertyList(forType: pasteboardType) as? NSArray {
            let itemsCount = board.count
            return itemsCount
        } else {
            os_log("Error opening pasteboard.", log: logUi, type: .error)
            return -1
        }
    }
    
    func getFileExtension(sender: NSDraggingInfo) -> String {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if board.count == 1 {
                let fileExtension = (board[0] as! NSString).pathExtension
                return fileExtension
            } else {
                os_log("More than one item in pasteboard.", log: logUi, type: .debug)
                return ""
            }
        } else {
            os_log("Error opening pasteboard.", log: logUi, type: .error)
            return ""
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if board.count == 1 {
                self.appPath = board[0] as! String
                self.iconPath = getAppIconPath(appPath: appPath)
                self.setAppIcnsFile()
                
                self.userDefaults.set(self.appPath, forKey: UserDefaultStruct.editorAppPath)
                self.userDefaults.set(self.iconPath, forKey: UserDefaultStruct.editorIconPath)
                
                NotificationCenter.default.post(name: Notification.Name("editorDropped"), object: nil)
                
                return true
            } else {
                os_log("More than one item in pasteboard.", log: logUi, type: .debug)
                return false
            }
        } else {
            os_log("Error opening pasteboard.", log: logUi, type: .error)
            return false
        }
    }
    
    func getAppIconPath(appPath: String) -> String {
        // The icon is specified in the app's Info.plist file in the key "CFBundleIconFile".
        let plistPath = appPath + "/Contents/Info.plist"
        let plistXML = FileManager.default.contents(atPath: plistPath)!
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml
        
        // Convert the data to a dictionary and handle errors.
        do {
            var plistData: [String: AnyObject] = [:]
            plistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &propertyListFormat) as! [String: AnyObject]
            
            // Extract the needed value from the dictionary.
            if let iconFileName = plistData["CFBundleIconFile"] as? String {
                os_log("Icon file is '%@' according to '%@'.", log: logUi, type: .debug, iconFileName, plistPath)
                var iconPath = appPath + "/Contents/Resources/" + iconFileName
                
                // Sometimes the icon name includes the ".icns" extension and sometimes not. Make sure to always include it when returning it.
                if !iconPath.hasSuffix(".icns") {
                    iconPath = iconPath + ".icns"
                }
                
                os_log("Icon file path is '%@'.", log: logUi, type: .debug, iconPath)
                return iconPath
            } else {
                os_log("No icon file found in '%@'.", log: logUi, type: .error, plistPath)
            }
        } catch let error {
            os_log("%@", log: logUi, type: .error, error.localizedDescription)
        }
        
        return ""
    }
    
    func setAppIcnsFile() {
        self.image = NSImage(contentsOfFile: self.iconPath)
    }
}
