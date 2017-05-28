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
    
    var fileTypeIsOk = false
    var droppedFilePath: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeHTML])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkType(drag: sender) {
            fileTypeIsOk = true
            return .copy
        } else {
            fileTypeIsOk = false
            return []
        }
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if fileTypeIsOk {
            return .copy
        } else {
            return []
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            // Save paths in bulk to one json file
            do {
                // Get the current datetime as a string
                let stringFromDate = Date().iso8601
                
                // Create SwiftyJSON object
                let jsonObject: JSON = ["datetime start": stringFromDate,
                                        "datetime end": "",
                                        "workflow": "just_rotate.json",
                                        //"workflow": "convert_for_kindle.json",
                    "items": board]
                
                // Convert SwiftyJSON object to string
                let jsonString = jsonObject.description
                //log.debug("jsonString: '\(jsonString)'")
                
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
        return false
    }
    
    func checkType(drag: NSDraggingInfo) -> Bool {
        if (drag.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") != nil) {
            return true
        }
        return false
    }
    
}
