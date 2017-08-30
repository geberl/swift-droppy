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
    var droppedTypeIsSupported = false
    var droppedFilePath: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Allow all types initially, but check again on draggingEntered if the currently selected Workflow supports this
        
        // Pboard types will be deprecated in a future release. So use UTIs instead.
        // https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

        // Register base types here to automatically allow all child types.
        // e.g. "public.image" for "public.tiff" and "public.jpg" ...
        register(forDraggedTypes: [
            "public.url",  // all urls (file, name, ...)
            "public.text", // all text (plain, rich, HTML, ...)
            "public.image" // all images (tiff, jpg, ...)
            ])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if Workflows.activeName == "" {
            workflowIsSelected = false
            NotificationCenter.default.post(name: Notification.Name("draggingEnteredNoWorkflowSelected"), object: nil)
            return .copy // allow drop (catch later, provide message -> better user experience)
            // return [] // don't even allow drop
        } else {
            workflowIsSelected = true

            if self.checkType(sender: sender) {
                droppedTypeIsSupported = true
                NotificationCenter.default.post(name: Notification.Name("draggingEnteredOk"), object: nil)
                return .copy
            } else {
                droppedTypeIsSupported = false
                NotificationCenter.default.post(name: Notification.Name("draggingEnteredNotOk"), object: nil)
                return .copy
            }
        }
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: Notification.Name("draggingExited"), object: nil)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        // Display eventual error messages after performDragOperation, after having discarded the dropped items.
        // Otherwise the mouse cursor still contains a green circle with a white plus symbol while clicking the 'Ok' button.

        if !workflowIsSelected {
            NotificationCenter.default.post(name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
        } else if !droppedTypeIsSupported {
            NotificationCenter.default.post(name: Notification.Name("unsupportedType"), object: nil)
        } else {
            if let board = sender?.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
                // Put filePaths into dict inside Notification.
                let pathDict:[String: NSArray] = ["filePaths": board]
                NotificationCenter.default.post(name: Notification.Name("droppingOk"), object: nil, userInfo: pathDict)
            }

            // Old version:
            //            if let board = sender.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            //                // Save paths in bulk to one json file
            //                do {
            //                    // Get the current datetime as a string
            //                    let stringFromDate = Date().iso8601
            //
            //                    // Create SwiftyJSON object
            //                    let jsonObject: JSON = ["datetime start": stringFromDate,
            //                                            "datetime end": "",
            //                                            "workflow": Workflows.activeJsonFile,
            //                                            "items": board]
            //
            //                    // Convert SwiftyJSON object to string
            //                    let jsonString = jsonObject.description
            //
            //                    // Setup objects needed for directory and file access
            //                    let tempDir: URL = FileManager.default.temporaryDirectory
            //                    let filePath: URL = tempDir.appendingPathComponent("droppy_date_here.json")
            //
            //                    // Write json string to file, this overwrites a preexisting file here
            //                    try jsonString.write(to: filePath, atomically: false, encoding: String.Encoding.utf8)
            //
            //                    // Send json file path to a function in ViewController
            //                    ViewControllerMain().runScriptJson(path: filePath.path)
            //                } catch {
            //                    log.error(error.localizedDescription)
            //                }
            //            }

        }
    }
    
    func checkType(sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard()

        // Iterate over accepted types of currently selected Workflow in its order of preference
        // Return as soon as a present type of the dropped item matches an accepted type of the Workflow
        for acceptedType in Workflows.activeAccepts {
            
            if String(acceptedType) == "filename" {
                
                if pasteboard.types?.contains("public.file-url") == true {
                    // File URLs from Finder (files, folders, drives)
                    // XCode (file)
                    // Mail (email)
                    log.debug("Returning: filename")
                    return true
                }
                
            } else if acceptedType == "url" {
                
                if pasteboard.types?.contains("public.url-name") == true ||
                    pasteboard.types?.contains("public.url") == true {
                    // Safari (image)
                    // Safari (url icon from adress bar)
                    // Safari (link)
                    // Vox (playlist item)
                    // iTunes (album, song)
                    // Mail (email)
                    // Calendar (item)
                    log.debug("Returning: url")
                    return false
                }
            } else if acceptedType == "image" {
                
                if pasteboard.types?.contains("public.image") == true ||
                    pasteboard.types?.contains("public.tiff") == true ||
                    pasteboard.types?.contains("public.fax") == true ||
                    pasteboard.types?.contains("public.jpeg") == true ||
                    pasteboard.types?.contains("public.jpeg-2000") == true ||
                    pasteboard.types?.contains("public.camera-raw-image") == true ||
                    pasteboard.types?.contains("public.png") == true ||
                    pasteboard.types?.contains("public.xbitmap-image") == true ||
                    pasteboard.types?.contains("com.apple.macpaint-image") == true ||
                    pasteboard.types?.contains("com.apple.pict") == true ||
                    pasteboard.types?.contains("com.apple.quicktime-image") == true ||
                    pasteboard.types?.contains("com.apple.icns") == true ||
                    pasteboard.types?.contains("com.adobe.photoshop-​image") == true ||
                    pasteboard.types?.contains("com.adobe.illustrator.ai-​image") == true ||
                    pasteboard.types?.contains("com.compuserve.gif") == true ||
                    pasteboard.types?.contains("com.microsoft.bmp") == true ||
                    pasteboard.types?.contains("com.microsoft.ico") == true ||
                    pasteboard.types?.contains("com.truevision.tga-image") == true ||
                    pasteboard.types?.contains("com.sgi.sgi-image") == true ||
                    pasteboard.types?.contains("com.ilm.openexr-image") == true ||
                    pasteboard.types?.contains("com.kodak.flashpix.image") == true {
                    // Safari (image) [tiff, nothing else ever seen]
                    log.debug("Returning: image")
                    return false
                }
                
            } else if acceptedType == "plaintext" {
                
                if pasteboard.types?.contains("public.plain-text") == true ||
                    pasteboard.types?.contains("public.source-code") == true ||
                    pasteboard.types?.contains("public.xml") == true ||
                    pasteboard.types?.contains("public.utf8-plain-text") == true ||
                    pasteboard.types?.contains("public.utf16-plain-text") == true ||
                    pasteboard.types?.contains("public.utf16-external-plain-text") == true {
                    // Sublime Text
                    // XCode (code)
                    // Safari (image)
                    // Safari (link)
                    // Safari (text)
                    // iTerm (text)
                    // Mail (email)
                    // Mail (content)
                    // Calendar (item)
                    
                    // MacVim, VS Code and Atom don't support dragging from them
                    log.debug("Returning: plaintext")
                    return false
                }
                
            } else if acceptedType == "richtext" {
                
                if pasteboard.types?.contains("public.rtf") == true ||
                    pasteboard.types?.contains("public.html") == true {
                    // TextEdit
                    // XCode (code)
                    // Safari (text)
                    // Mail (content)
                    log.debug("Returning: richtext")
                    return false
                }
    
            }
        }
        log.debug("Workflow doesn't accept any types of the dropped item, just \(Workflows.activeAccepts).")
        return false

    }
}
