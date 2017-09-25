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
            "com.apple.resolvable"     // Items that the Alias Manager can resolve.
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
            // TODO: Probably do something more/else for other pboardtypes here (url, plaintext, ...).
            if let plist = sender?.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
                log.debug("NSFilenamesPboardType")
                // Put filePaths into dict inside Notification.
                let pathDict:[String: NSArray] = ["filePaths": plist]
                NotificationCenter.default.post(name: Notification.Name("droppingOk"), object: nil, userInfo: pathDict)
                
                log.debug(" \(plist)")
                
                // file from finder: file path
                // folder from finder: file path
                // file from tower: file path
                // file from xcode: file path
                // album from itunes: all the paths of the contained songs, eg ~/Music/iTunes/iTunes Media/Music/Artist/Album/Song.mp3.
                // song from itunes: path to the song, eg "/Users/guenther/Music/iTunes/iTunes Media/Music/Jack Johnson/All The Light Above It Too/1-02 You Can't Control It.mp3"
            }

            // Specify the interesting sub-types here, and associate them with a file extension.
            let dataTypes: Dictionary<String, String> = ["com.adobe.encapsulated-​postscript": "eps",
                                                         "com.adobe.illustrator.ai-​image": "ai",
                                                         "com.adobe.pdf": "pdf",
                                                         "com.adobe.photoshop-​image": "psd",
                                                         "com.adobe.postscript": "ps",
                                                         "com.adobe.postscript.pfa-​font": "pfa",
                                                         "com.adobe.postscript-pfb-​font": "pfb",
                                                         "com.apple.applescript.​script": "scpt",
                                                         "com.apple.applescript.text": "applescript",
                                                         "com.apple.application-​bundle": "app",
                                                         "com.apple.binhex-archive": "hqx",
                                                         "com.apple.bundle": "bundle",
                                                         "com.apple.colorsync-profile": "icc",
                                                         "com.apple.coreaudio-​format": "caf",
                                                         "com.apple.dashboard-​widget": "wdgt",
                                                         "com.apple.font-suitcase": "suit",
                                                         "com.apple.framework": "framework",
                                                         "com.apple.icns": "icns",
                                                         "com.apple.itunes.metadata": "xml",
                                                         "com.apple.macbinary-​archive": "bin",
                                                         "com.apple.macpaint-image": "pntg",
                                                         "com.apple.metadata-​importer": "mdimporter",
                                                         "com.apple.pict": "pict",
                                                         "com.apple.plugin": "plugin",
                                                         "com.apple.protected-​mpeg-4-audio": "m4p",
                                                         "com.apple.quartz-​composer-composition": "qtz",
                                                         "com.apple.quicktime-image": "qtif",
                                                         "com.apple.quicktime-movie": "mov",
                                                         "com.apple.rez-source": "r",
                                                         "com.apple.rtfd": "rtfd",
                                                         "com.apple.symbol-export": "exp",
                                                         "com.apple.traditional-mac-​plain-text": "txt",
                                                         "com.apple.truetype-​datafork-suitcase-font": "dfont",
                                                         "com.apple.txn.text-​multimedia-data": "txtn",
                                                         "com.apple.webarchive": "webarchive",
                                                         "com.microsoft.windows-​executable": "exe",
                                                         "com.microsoft.windows-​dynamic-link-library": "dll",
                                                         "com.netscape.javascript-​source": "js",
                                                         "com.pkware.zip-archive": "zip",
                                                         "com.sun.java-class": "class",
                                                         "com.sun.java-archive": "jar",
                                                         "com.sun.java-source": "java",
                                                         "com.sun.java-web-start": "jnlp",
                                                         "org.gnu.gnu-tar-archive": "gtar",
                                                         "org.gnu.gnu-zip-archive": "gzip",
                                                         "org.gnu.gnu-zip-tar-archive": "tgz",
                                                         "public.3gpp": "3gp",
                                                         "public.3gpp2": "3gp2",
                                                         "public.aifc-audio": "aifc",
                                                         "public.aiff-audio": "aiff",
                                                         "public.assembly-source": "a",
                                                         "public.avi": "avi",
                                                         "public.c-plus-plus-header": "hpp",
                                                         "public.c-plus-plus-source": "cpp",
                                                         "public.c-header": "h",
                                                         "public.c-source": "c",
                                                         "public.cpio-archive": "cpio",
                                                         "public.csh-script": "csh",
                                                         "public.file-url": "txt",
                                                         "public.html": "html",
                                                         "public.jpeg": "jpg",
                                                         "public.jpeg-2000": "jp2",
                                                         "public.mig-source": "mig",
                                                         "public.mp3": "mp3",
                                                         "public.mpeg": "mpg",
                                                         "public.mpeg-4": "mp4",
                                                         "public.mpeg-4-audio": "m4a",
                                                         "public.object-code": "o",
                                                         "public.objective-c-plus-​plus-source": "mm",
                                                         "public.objective-c-source": "m",
                                                         "public.opentype-font": "otf",
                                                         "public.perl-script": "pl",
                                                         "public.php-script": "php",
                                                         "public.plain-text": "txt",
                                                         "public.png": "png",
                                                         "public.python-script": "py",
                                                         "public.rtf": "rtf",
                                                         "public.ruby-script": "rb",
                                                         "public.shell-script": "sh",
                                                         "public.tar-archive": "tar",
                                                         "public.truetype-ttf-font": "ttf",
                                                         "public.truetype-collection-​font": "ttc",
                                                         "public.tiff": "tiff",
                                                         "public.ulaw-audio": "au",
                                                         "public.url": "txt",
                                                         "public.url-name": "txt",
                                                         "public.utf8-plain-text": "txt",
                                                         "public.utf16-external-plain-text": "txt",
                                                         "public.utf16-plain-text": "txt",
                                                         "public.vcard": "vcf",
                                                         "public.xbitmap-image": "xbm",
                                                         "public.xml": "xml"
                                                         ]
            
            for (dataType, fileExtension) in dataTypes {
                if let data = sender?.draggingPasteboard().data(forType: dataType) {
                    log.debug("Writing '" + dataType + "' data to file.")

                    do {
                        try data.write(to: URL(fileURLWithPath: "/Users/guenther/Downloads/stuff/" + dataType + "." + fileExtension))
                    } catch let error {
                        log.error("Unable to write '" + dataType + "' data to file.")
                        log.error(error.localizedDescription)
                    }
                } else {
                    log.debug("No '" + dataType + "' data available.")
                }
            }

            
            // Promises
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "NSPromiseContentsPboardType"))")
            // email from mail: nil
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.pasteboard.promised-file-url"))")
            // appointment from calendar: nil
            
            // Mail
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.mail.PasteboardTypeMessageTransfer"))")
            // email from mail: nil
            
            // Cal

            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.iCal.pasteboard.event"))")
            // appointment from calendar: some weird identifier number (5A3ED2FB-76D9-44AB-BF13-40B171808AE4)
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.iCal.pasteboard.dragOriginDate"))")
            // appointment from calendar: a bit of json, containing the NS.time as an integer
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.cocoa.pasteboard.color"))")
            // appointment from calendar: a lot of data, but nothing useable
            
            // iTunes
            
            //log.debug("\(sender?.draggingPasteboard().propertyList(forType: "com.apple.itunes.metadata"))")
            // album from itunes: dictionary containing album and song metadata (useful!)
            // song from itunes: dictionary containing song metadata (useful!)
            
            // These two work for text from xcode!
            //log.debug("\(sender?.draggingPasteboard().string(forType: "public.utf8-plain-text"))")
            //log.debug("\(sender?.draggingPasteboard().data(forType: "public.utf8-plain-text"))")
            
            log.debug("\(sender!.draggingPasteboard().types)")
            
            // "NSTIFFPboardType"
//                "NSURLPboardType"
//                "NSFileContentsPboardType"
//                "NSCreateFileContentsPboardType"
//                "NSTIFFPboardType" // tiff, gif, jpg, and others
//                "NSPDFPboardType" // pdf
//                "NSPostscriptPboardType" // eps
//                "NSPICTPboardType" // pict
//                "NSFontPboardType" // font
//                "NSRulerPboardType" // ruler
            

        }
    }

}
