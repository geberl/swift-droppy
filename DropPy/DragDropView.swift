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

        // Pboard types will be deprecated in a future release. Use UTIs instead.
        // https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

        // Register all base types here to automatically allow all child types.
        // So basicall everything that has '-' in its "conforms to" column in the documentation.
        register(forDraggedTypes: [
            "public.item",              // Base type for the physical hierarchy.
            "public.content",           // Base type for all document content.
            "public.database",          // Base functional type for databases.
            "public.calendar-event",    // Base functional type for scheduled events.
            "public.message",           // Base type for messages (email, IM, and so on).
            "public.contact",           // Base type for contact information.
            "public.archive",           // Base type for an archive of files and directories.
            "public.url-name",          // URL name.
            "public.executable",        // Base type for executable data.
            "com.apple.resolvable"      // Items that the Alias Manager can resolve.
            ])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if AppState.activeName == "" {
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
            NotificationCenter.default.post(name: Notification.Name("draggingExited"), object: nil)
        } else {
            if let pasteboard = sender?.draggingPasteboard() {
                let pasteboardDict:[String: NSPasteboard] = ["draggingPasteboard": pasteboard]
                NotificationCenter.default.post(name: Notification.Name("droppingOk"),
                                                object: nil,
                                                userInfo: pasteboardDict)
            }
        }
    }
}
