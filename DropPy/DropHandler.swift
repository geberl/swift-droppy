//
//  DropHandler.swift
//  DropPy
//
//  Created by Günther Eberl on 26.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import Cocoa


class DropHandler: NSObject {
    
    var draggingPasteboard: NSPasteboard
    var workspacePath: String
    var devModeEnabled: Bool = false
    
    let startDateTime = Date()
    var tempPath: String
    var logFilePath: String
    var dirZeroUrl: URL
    var utiTypes: [String]
    var overallExitCode: Int

    init(draggingPasteboard: NSPasteboard, workspacePath: String, devModeEnabled: Bool) {
        log.debug("Handling dropped objects.")
        
        self.draggingPasteboard = draggingPasteboard
        self.workspacePath = workspacePath
        self.devModeEnabled = devModeEnabled
        
        if self.devModeEnabled {
            self.tempPath = self.workspacePath + "Temp" + "/" + self.startDateTime.iso8601 + "/"
        } else {
            self.tempPath = NSTemporaryDirectory() + "DropPy" + "/" + self.startDateTime.iso8601 + "/"
        }
        self.logFilePath = tempPath + "droppy.log"
        self.dirZeroUrl = URL(fileURLWithPath: self.tempPath + "0")
        self.utiTypes = []
        self.overallExitCode = 0
        
        super.init()
    }
    
    func run() {
        self.prepareTempDir()
        self.getUtiTypes()
        self.writeDropLog()
        self.symlinkFiles()
        self.writeUtiData()
    }
    
    func prepareTempDir() {
        // Create the {temp}/0/files directory, this automatically creates all parent directories.
        let dirZeroFilesPath: String = self.dirZeroUrl.path + "/" + "files" + "/"
        if !isDir(path: dirZeroFilesPath) {
            makeDirs(path: dirZeroFilesPath)
        }
    }
    
    func symlinkFiles() {
        let dirZeroFilesPath: String = self.dirZeroUrl.path + "/" + "files" + "/"
        
        // Symlink the originally dropped files.
        let fileManager = FileManager.default
        for srcPath in self.getFilePaths() {
            let srcURL: URL = URL(fileURLWithPath: srcPath)
            
            var dstURL: URL = URL(fileURLWithPath: dirZeroFilesPath)
            dstURL.appendPathComponent(srcURL.lastPathComponent)
            
            do {
                try fileManager.createSymbolicLink(at: dstURL, withDestinationURL: srcURL)
            } catch {
                log.error("Unable to symlink file '\(srcPath)'.")
            }
        }
        
        // Delete all .DS_Store files.
        guard let enumerator: FileManager.DirectoryEnumerator =
            fileManager.enumerator(atPath: dirZeroFilesPath) else {
                log.error("Directory not found: \(dirZeroFilesPath)!")
                return
        }
        
        while let element = enumerator.nextObject() as? String {
            let elementPath = dirZeroFilesPath + element
            let elementURL: URL = URL(fileURLWithPath: elementPath)
            if elementURL.lastPathComponent == ".DS_Store" {
                do {
                    try fileManager.removeItem(atPath: elementPath)
                } catch let error {
                    log.error(error.localizedDescription)
                }
            }
        }
    }
    
    func getFilePaths() -> [String] {
        // No luck getting this to work with "public.file-url" instead of "NSFilenamesPboardType"
        // https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html

        if let filePathsArray = self.draggingPasteboard.propertyList(forType: "NSFilenamesPboardType") as? NSArray {
            if let filePaths = filePathsArray as? [String] {
                return filePaths
            }
        }
        return []
    }
    
    func getUtiTypes() {
        if let types = self.draggingPasteboard.types {
            for type in types {
                if self.isUtiType(typeName: type) {
                    self.utiTypes.append(type)
                }
            }
        } else {
            log.error("Something is wrong with the passed NSPasteboard (types is nil).")
            self.overallExitCode = 1
        }
        
        if self.utiTypes.count == 0 {
            log.error("No UTI types contained in NSPasteboard.")
            self.overallExitCode = 1
        }
        
        self.utiTypes = self.utiTypes.sorted()
    }
    
    func isUtiType(typeName: String) -> Bool {
        // Criterium 1: String must only consist of lowercase letters.
        if !(typeName.lowercased() == typeName) { return false }
        
        // Criterium 2: String must not contain any spaces.
        if !(typeName.trimmingCharacters(in: NSCharacterSet.whitespaces) == typeName) { return false }
        
        // Criterium 3: String must contain at least one "." character.
        if typeName.range(of: ".") == nil { return false }
        
        // Criterium 4: String must not start with "dyn.".
        if typeName.hasPrefix("dyn.") { return false }
        
        // All criteria fulfilled.
        return true
    }
    
    func writeDropLog() {
        // Create an empty file at logFilePath.
        do {
            try "".write(to: URL(fileURLWithPath: self.logFilePath),
                         atomically: false,
                         encoding: String.Encoding.utf8)
        } catch let error {
            log.error(error.localizedDescription)
            self.overallExitCode = 1
            return
        }
        
        // Write some basic info into it.
        self.writeLog(prefix: "Start Date & Time:        ", lines: [self.startDateTime.readable])
        self.writeLog(prefix: "Dev Mode Enabled:         ", lines: ["\(self.devModeEnabled)"])
        self.writeLog(prefix: "Dropped Object Datatypes: ", lines: self.utiTypes)
        self.writeLog(prefix: "Workspace Path:           ", lines: [self.workspacePath])
        self.writeLog(prefix: "Temp Path:                ", lines: [self.tempPath])
        self.writeLog(prefix: "Logfile Path:             ", lines: [self.logFilePath])
    }
    
    func writeLog(prefix: String, lines: [String]) {
        // The file is guaranteed to exist at that point, it may have content or be empty.
        var prefixedLine: String
        if let fileHandle = FileHandle(forWritingAtPath: self.logFilePath) {
            defer {
                fileHandle.closeFile()
            }
            for (n, line) in lines.enumerated() {
                if n == 0 {
                    prefixedLine = prefix + line + "\n"
                } else {
                    prefixedLine = String(repeating: " ", count: prefix.characters.count) + line + "\n"
                }
                
                if let lineData = prefixedLine.data(using: String.Encoding.utf8) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(lineData)
                }
            }
        }
    }
    
    func writeUtiData() {
        // Specify the known sub-types here, and associate them with a file extension.
        // Currently only used to guess the correct file extension, not to iterate over it.
        let knownUtiDataTypes: Dictionary<String, String> = ["com.adobe.encapsulated-​postscript": "eps",
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

        for dataType in self.utiTypes {
            if let data = self.draggingPasteboard.data(forType: dataType) {
                do {
                    var fileExtension: String = "txt"
                    if knownUtiDataTypes[dataType] != nil {
                        fileExtension = knownUtiDataTypes[dataType]!
                    }
                    let dataURL: URL = URL(fileURLWithPath: self.dirZeroUrl.path + "/" + dataType + "." + fileExtension)
                    try data.write(to: dataURL)
                } catch let error {
                    log.error("Unable to write '" + dataType + "' data to file.")
                    log.error(error.localizedDescription)
                }
            }
        }
    }
    
    func evaluate() -> (String, String, Int) {
        return (self.logFilePath, self.tempPath, self.overallExitCode)
    }
}
