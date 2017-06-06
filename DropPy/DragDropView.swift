//
//  MyImageView.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON


extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

class DragDropView: NSView {
    
    var workflowIsSelected = false
    var fileTypeIsOk = false
    var droppedFilePath: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeHTML])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if Workflows.activeName == "" {
            workflowIsSelected = false
            NotificationCenter.default.post(name: Notification.Name("draggingEnteredNoWorkflowSelected"), object: nil)
            return .copy // allow drop (catch later, provide message)
            // return [] // don't allow drop
        } else {
            workflowIsSelected = true

            if self.checkType(drag: sender) {
                fileTypeIsOk = true
                NotificationCenter.default.post(name: Notification.Name("draggingEnteredOk"), object: nil)
                return .copy
            } else {
                fileTypeIsOk = false
                NotificationCenter.default.post(name: Notification.Name("draggingEnteredNotOk"), object: nil)
                return .copy // allow drop (catch later, provide message)
                // return [] // don't allow drop
            }
        }
    }

    override func draggingEnded(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: Notification.Name("draggingEnded"), object: nil)
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: Notification.Name("draggingExited"), object: nil)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if workflowIsSelected == false {
            // Display error message
            NotificationCenter.default.post(name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
            
        } else if fileTypeIsOk == false {
            // Display error message
            NotificationCenter.default.post(name: Notification.Name("unsupportedFileType"), object: nil)  // TODO not implemented
            
        } else {
            // Process files
        
            if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
                // Save paths in bulk to one json file
                do {
                    // Get the current datetime as a string
                    let stringFromDate = Date().iso8601
                
                    // Create SwiftyJSON object
                    let jsonObject: JSON = ["datetime start": stringFromDate,
                                            "datetime end": "",
                                            "workflow": Workflows.activeJsonFile,
                                            "items": board]
                
                    // Convert SwiftyJSON object to string
                    let jsonString = jsonObject.description
                
                    // Setup objects needed for directory and file access
                    let tempDir: URL = FileManager.default.temporaryDirectory
                    let filePath: URL = tempDir.appendingPathComponent("droppy_date_here.json")
                
                    // Write json string to file, this overwrites a preexisting file here
                    try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
                
                    // Send json file path to a function in ViewControler
                    ViewController().runScriptJson(path: filePath.path)
                } catch {
                    log.error(error.localizedDescription)
                }
                return true
            }
            return true
        }
        return true
    }
    
    func checkType(drag: NSDraggingInfo) -> Bool {
        if (drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") != nil) {
            return true
        }
        return false
    }
}
