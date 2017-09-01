//
//  MyImageView.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON


class DragDropView: NSView {
    
    var workflowIsSelected = false
    var droppedFilePath: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Allow all types here. Just convert everything to a file.

        // Pboard types will be deprecated in a future release. So use UTIs instead.
        // https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

        // Register base types here to automatically allow all child types.
        // e.g. "public.image" for "public.tiff" and "public.jpg" ...
        register(forDraggedTypes: [
            "public.url",  // all urls (file, folder, name, ...)
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
            NotificationCenter.default.post(name: Notification.Name("draggingEnteredOk"), object: nil)
            return .copy
        }
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: Notification.Name("draggingExited"), object: nil)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        // Display error messages only AFTER performDragOperation, basicall after macOS has discarded the dropped items.
        // Otherwise the mouse cursor still contains a green circle with a white plus symbol while clicking the 'Ok' button.

        if !workflowIsSelected {
            NotificationCenter.default.post(name: Notification.Name("actionOnEmptyWorkflow"), object: nil)
            NotificationCenter.default.post(name: Notification.Name("draggingExited"), object: nil)
        } else {
            // TODO: Probably do something more/else for other pboardtypes here (url, plaintext, ...).
            if let board = sender?.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
                // Put filePaths into dict inside Notification.
                let pathDict:[String: NSArray] = ["filePaths": board]
                NotificationCenter.default.post(name: Notification.Name("droppingOk"), object: nil, userInfo: pathDict)
            }
        }
    }

}
