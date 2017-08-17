//
//  ViewControllerEditorPrefs.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerEditorPrefs: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var editorIcon: EditorAppImageView!
    
    @IBOutlet weak var workflowEditor: NSPopUpButton!
    
    @IBOutlet weak var taskEditor: NSPopUpButton!

    override func viewWillAppear() {
        super.viewWillAppear()
        self.loadSettings()
    }
    
    override func viewWillDisappear() {
        self.saveSettings()
        super.viewWillDisappear()
    }
    
    @IBAction func onButtonClearEditor(_ sender: Any) {
        self.editorIcon.appPath = ""
        self.editorIcon.iconPath = ""
        self.editorIcon.image = nil
        
        if (self.workflowEditor.selectedItem != nil) {
            if self.workflowEditor.selectedItem!.title == "External text editor" {
                self.workflowEditor.selectItem(withTitle: UserDefaultStruct.editorForWorkflowsDefault)
            }
        }
        
        if (self.taskEditor.selectedItem != nil) {
            if self.taskEditor.selectedItem!.title == "External text editor" {
                self.taskEditor.selectItem(withTitle: UserDefaultStruct.editorForTasksDefault)
            }
        }
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://droppyapp.com/settings/editor"), NSWorkspace.shared().open(url) {
            log.debug("Documentation site for Editor openened.")
        }
    }

    func loadSettings() {
        if let appPathString:String = userDefaults.string(forKey: UserDefaultStruct.editorAppPath) {
            self.editorIcon.appPath = appPathString
        }
        
        if let editorIconPathString:String = userDefaults.string(forKey: UserDefaultStruct.editorIconPath) {
            self.editorIcon.iconPath = editorIconPathString
            self.editorIcon.setAppIcnsFile()
        }

        if let workflowEditorString:String = self.userDefaults.string(forKey: UserDefaultStruct.editorForWorkflows) {
            self.workflowEditor.selectItem(withTitle: workflowEditorString)
        }

        if let taskEditorString:String = self.userDefaults.string(forKey: UserDefaultStruct.editorForTasks) {
            self.taskEditor.selectItem(withTitle: taskEditorString)
        }
    }
    
    func saveSettings() {
        self.userDefaults.set(self.editorIcon.appPath, forKey: UserDefaultStruct.editorAppPath)
        self.userDefaults.set(self.editorIcon.iconPath, forKey: UserDefaultStruct.editorIconPath)

        if (self.workflowEditor.selectedItem != nil) {
            self.userDefaults.set(self.workflowEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForWorkflows)
        } else {
            self.userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
        }

        if (self.taskEditor.selectedItem != nil) {
            self.userDefaults.set(self.taskEditor.selectedItem!.title, forKey: UserDefaultStruct.editorForTasks)
        } else {
            self.userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }
    }
}

class EditorAppImageView: NSImageView {

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
            log.debug("Type contains '\(pasteboardType)'.")
            return true
        } else {
            log.debug("Type doesn't contain '\(pasteboardType)'.")
            return false
        }
    }
    
    func countNumberOfItems(sender: NSDraggingInfo, pasteboardType: String) -> Int {
        if let board = sender.draggingPasteboard().propertyList(forType: pasteboardType) as? NSArray {
            let itemsCount = board.count
            log.debug("Found \(itemsCount) \(pasteboardType)s in pasteboard.")
            return itemsCount
        } else {
            log.debug("Error opening pasteboard.")
            return -1
        }
    }
    
    func getFileExtension(sender: NSDraggingInfo) -> String {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if board.count == 1 {
                let fileExtension = (board[0] as! NSString).pathExtension
                log.debug("File extension is '\(fileExtension)'.")
                return fileExtension
            } else {
                log.debug("More than one item in pasteboard.")
                return ""
            }
        } else {
            log.debug("Error opening pasteboard.")
            return ""
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if board.count == 1 {
                self.appPath = board[0] as! String
                self.iconPath = getAppIconPath(appPath: appPath)
                self.setAppIcnsFile()
                return true
            } else {
                log.debug("More than one item in pasteboard.")
                return false
            }
        } else {
            log.debug("Error opening pasteboard.")
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
                log.debug("Icon file is '\(iconFileName)' in '\(plistPath)'.")
                var iconPath = appPath + "/Contents/Resources/" + iconFileName
                
                // Sometimes the icon name includes the ".icns" extension and sometimes not. Make sure to always include it when returning it.
                if !iconPath.hasSuffix(".icns") {
                    iconPath = iconPath + ".icns"
                }
                
                log.debug("Icon file path is '\(iconPath)'.")
                return iconPath
            } else {
                log.debug("No icon file found in '\(plistPath)'.")
            }
        } catch {
            log.debug("Error reading plist: \(error), format: \(propertyListFormat)")
        }
        
        return ""
    }
    
    func setAppIcnsFile() {
        self.image = NSImage(contentsOfFile: self.iconPath)
        log.debug("Image of editor set to '\(self.iconPath)'")
    }
}
