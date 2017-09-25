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
            if let plist = sender?.draggingPasteboard().propertyList(forType: "NSFilenamesPboardType") as? NSArray {
                // Put filePaths into dict inside Notification.
                let pathDict:[String: NSArray] = ["filePaths": plist]
                NotificationCenter.default.post(name: Notification.Name("droppingOk"), object: nil, userInfo: pathDict)
                
                log.debug("NSFilenamesPboardType")
                log.debug(" \(plist)")
            }
            
            if let plist = sender?.draggingPasteboard().propertyList(forType: "public.file-url") {
                log.debug("public.file-url")
                log.debug(" \(plist)")  // file:///.file/id=6571367.11780549
                // TODO: can the filemanager resolve this?
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
                                                         "com.apple.finder.node": "txt",
                                                         "com.apple.font-suitcase": "suit",
                                                         "com.apple.framework": "framework",
                                                         "com.apple.icns": "icns",
                                                         "com.apple.itunes.metadata": "xml",
                                                         "com.apple.keynote.key": "key",
                                                         "com.apple.keynote.kth": "kth",
                                                         "com.apple.macbinary-​archive": "bin",
                                                         "com.apple.macpaint-image": "pntg",
                                                         "com.apple.mail.PasteboardTypeMessageTransfer": "txt",
                                                         "com.apple.mail.PasteboardTypeAutomator": "xml",
                                                         "com.apple.metadata-​importer": "mdimporter",
                                                         "com.apple.pasteboard.promised-file-url": "txt",
                                                         "com.apple.pasteboard.promised-file-content-type": "txt",
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
                                                         "com.allume.stuffit-archive": "sit",
                                                         "com.compuserve.gif": "gif",
                                                         "com.digidesign.sd2-audio": "sd2",
                                                         "com.ilm.openexr-image": "exr",
                                                         "com.js.efx-fax": "efx",
                                                         "com.j2.jfx-fax": "jfx",
                                                         "com.kodak.flashpix.image": "fpx",
                                                         "com.microsoft.advanced-​systems-format": "asf",
                                                         "com.microsoft.advanced-​stream-redirector": "asx",
                                                         "com.microsoft.bmp": "bmp",
                                                         "com.microsoft.excel.xls": "xls",
                                                         "com.microsoft.ico": "ico",
                                                         "com.microsoft.powerpoint.​ppt": "ppt",
                                                         "com.microsoft.waveform-​audio": "wav",
                                                         "com.microsoft.windows-​executable": "exe",
                                                         "com.microsoft.windows-​dynamic-link-library": "dll",
                                                         "com.microsoft.word.doc": "doc",
                                                         "com.microsoft.windows-​media-wax": "wax",
                                                         "com.microsoft.windows-​media-wm": "wm",
                                                         "com.microsoft.windows-​media-wma": "wma",
                                                         "com.microsoft.windows-​media-wmp": "wmp",
                                                         "com.microsoft.windows-​media-wmv": "wmv",
                                                         "com.microsoft.windows-​media-wmx": "wmx",
                                                         "com.microsoft.windows-​media-wvx": "wvx",
                                                         "com.netscape.javascript-​source": "js",
                                                         "com.pkware.zip-archive": "zip",
                                                         "com.real.realmedia": "rm",
                                                         "com.real.realaudio": "ra",
                                                         "com.real.smil": "smil",
                                                         "com.sgi.sgi-image": "sgi",
                                                         "com.sun.java-class": "class",
                                                         "com.sun.java-archive": "jar",
                                                         "com.sun.java-source": "java",
                                                         "com.sun.java-web-start": "jnlp",
                                                         "com.truevision.tga-image": "tga",
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

            log.debug("\(sender!.draggingPasteboard().types ?? ["nil"])")
            
        }
    }

}
