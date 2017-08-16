//
//  ViewControllerEditor.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerEditor: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.applySettings()
    }

    @IBAction func onButtonRestoreDefault(_ sender: NSButton) {
        userDefaults.set(UserDefaultStruct.editorAppDefault, forKey: UserDefaultStruct.editorApp)
    }
    
    @IBAction func onHelpButton(_ sender: NSButton) {
        if let url = URL(string: "https://www.google.com"), NSWorkspace.shared().open(url) {
            log.debug("Help site for Editor openened.")
        }
    }
    
    @IBOutlet weak var radioInternal: NSButton!
    
    @IBOutlet weak var radioExternal: NSButton!

    @IBAction func onRadioWorkflowEditor(_ sender: NSButton) {
        if sender.title == "External text editor" {
            userDefaults.set(true, forKey: UserDefaultStruct.useTextEditorForWorkflows)
            }
        if sender.title == "Internal Workflow editor" {
            userDefaults.set(false, forKey: UserDefaultStruct.useTextEditorForWorkflows)
        }
    }
    
    func applySettings() {
        if userDefaults.bool(forKey: UserDefaultStruct.useTextEditorForWorkflows) == true {
            radioInternal.state = 0
            radioExternal.state = 1
        } else {
            radioInternal.state = 1
            radioExternal.state = 0
        }
    }
}

class EditorAppImageView: NSImageView {

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
                let appPath = board[0] as! String
                let appIconFilePath = getAppIconFilePath(appPath: appPath)

                self.image = NSImage(contentsOfFile: appIconFilePath)

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
    
    func getAppIconFilePath(appPath: String) -> String {
        // The icon is specified in the app's Info.plist file in the key "CFBundleIconFile".
        let plistFilePath = appPath + "/Contents/Info.plist"
        let plistXML = FileManager.default.contents(atPath: plistFilePath)!
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml
        
        // Convert the data to a dictionary and handle errors.
        do {
            var plistData: [String: AnyObject] = [:]
            plistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &propertyListFormat) as! [String: AnyObject]
            
            // Extract the needed value from the dictionary.
            if let iconFileName = plistData["CFBundleIconFile"] as? String {
                log.debug("Icon file is '\(iconFileName)' in '\(plistFilePath)'.")
                var iconFilePath = appPath + "/Contents/Resources/" + iconFileName
                
                // Sometimes the icon name includes the ".icns" extension and sometimes not.
                // Make sure to always include it when returning it.
                if !iconFilePath.hasSuffix(".icns") {
                    iconFilePath = iconFilePath + ".icns"
                }
                
                log.debug("Icon file path is '\(iconFilePath)'.")
                return iconFilePath
            } else {
                log.debug("No icon file found in '\(plistFilePath)'.")
            }
        } catch {
            log.debug("Error reading plist: \(error), format: \(propertyListFormat)")
        }
        
        return ""
    }
}
