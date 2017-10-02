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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Allow all types here. Just convert everything to a file later.

        // Pboard types will be deprecated in a future release. Use UTIs instead.
        // https://developer.apple.com/library/content/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html

        // Register all base types here to automatically allow all child types.
        // So basicall everything that has '-' in its "conforms to" column in the above documentation.
        registerForDraggedTypes([
            NSPasteboard.PasteboardType(rawValue: "public.item"),              // Base type for the physical hierarchy.
            NSPasteboard.PasteboardType(rawValue: "public.content"),           // Base type for all document content.
            NSPasteboard.PasteboardType(rawValue: "public.database"),          // Base functional type for databases.
            NSPasteboard.PasteboardType(rawValue: "public.calendar-event"),    // Base functional type for scheduled events.
            NSPasteboard.PasteboardType(rawValue: "public.message"),           // Base type for messages (email, IM, and so on).
            NSPasteboard.PasteboardType(rawValue: "public.contact"),           // Base type for contact information.
            NSPasteboard.PasteboardType(rawValue: "public.archive"),           // Base type for an archive of files and directories.
            NSPasteboard.PasteboardType(rawValue: "public.url-name"),          // URL name.
            NSPasteboard.PasteboardType(rawValue: "public.executable"),        // Base type for executable data.
            NSPasteboard.PasteboardType(rawValue: "com.apple.resolvable")      // Items that the Alias Manager can resolve.
            ])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if AppState.activeName == "" {
            NotificationCenter.default.post(name: .draggingEnteredError, object: nil)
            return [] // don't even allow drop.
        } else {
            NotificationCenter.default.post(name: .draggingEnteredOk, object: nil)
            return .copy
        }
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        NotificationCenter.default.post(name: .draggingExited, object: nil)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // FilePromises only work as long as the drag operation is being performed, not afterwards. FilePromises do
        // not exist as actual files somewhere on the disk, instead the parent application manages them abstraced,
        // probably in some internal database. It only writes them out when asked to. And this is what the function
        // receivePromisedFiles does. The file are only guaranteed to exist after its reader function is called,
        // not right here in performDragOperation.
        // https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/DragandDrop/Tasks/DraggingFiles.html
        
        // More info: "What's New in Cocoa" presentation at WWDC 2016
        // https://developer.apple.com/videos/play/wwdc2016/203/ (24:12 to 28:25)
        // http://devstreaming.apple.com/videos/wwdc/2016/203x2w42att1kdzg1ce/203/203_whats_new_in_cocoa.pd (p 132)
        
        // Introduced in Sierra (macOS 10.12) which I require anyways -> nice coincidence.
        // NOBODY in GitHub or the web has this implemented as of yet (2017-10-02) -> profit!
        
//        if let filePromises = sender.draggingPasteboard().readObjects(forClasses: [NSFilePromiseReceiver.self],
//                                                                      options: nil) as? [NSFilePromiseReceiver] {
//            let promiseOperationQueue: OperationQueue = OperationQueue()
//            for filePromise in filePromises {
//                print(filePromise)
//                print(filePromise.fileNames)  // []
//                print(filePromise.fileTypes)  // "public.jpeg"
//
//                let myFilePath: String = "/Users/guenther/Development/droppy-workspace/Temp/promises/"
//                filePromise.receivePromisedFiles(atDestination: URL(fileURLWithPath: myFilePath),
//                                                 operationQueue: promiseOperationQueue,
//                                                 reader: self.myReaderBlock)
//            }
//        }
        
        return true
    }
    
    func myReaderBlock(myUrl: URL, myError: Error?) {
        print("reader block called")
        
        print(myUrl.path)
        print(isFile(path: myUrl.path))
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        if let pasteb = sender?.draggingPasteboard() {
            let pastebDict:[String: NSPasteboard] = ["draggingPasteboard": pasteb]
            NotificationCenter.default.post(name: .droppingOk, object: nil, userInfo: pastebDict)
        }
    }
}
