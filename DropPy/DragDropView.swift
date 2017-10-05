//
//  MyImageView.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import SwiftyJSON
import os.log


class DragDropView: NSView {
    
    var startTime: DispatchTime?
    var numberOfPromises: Int
    var numberOfExtractedPromises: Int
    var tempDirPath: String
    var logFilePath: String
    var executionCancel: Bool
    
    required init?(coder: NSCoder) {
        startTime = nil
        numberOfPromises = 0
        numberOfExtractedPromises = 0
        tempDirPath = ""
        logFilePath = ""
        executionCancel = false
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(DragDropView.cancelExecution),
                                               name: .executionCancel, object: nil)
    }
    
    @objc func cancelExecution(_ notification: Notification) {
        self.executionCancel = true
        
        // Clear status text before sending executionFinished to avoid the text hanging at "Waiting ...".
        let statusDict:[String: String] = ["text": ""]
        NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
        
        NotificationCenter.default.post(name: .executionFinished, object: nil)
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
        NotificationCenter.default.post(name: .droppingStarted, object: nil)
        
        let statusDict:[String: String] = ["text": "Creating files\nPlease wait a moment"]
        NotificationCenter.default.post(name: .executionStatus, object: nil, userInfo: statusDict)
        
        // Reset class variables from last time.
        self.numberOfPromises = 0
        self.numberOfExtractedPromises = 0
        self.startTime = DispatchTime.now()
        self.executionCancel = false
        
        var zeroDirPath: String
        var filesDirPath: String
        var promisesDirPath: String
        (self.tempDirPath, self.logFilePath, zeroDirPath, filesDirPath, promisesDirPath) = self.getPaths()
        
        if !self.executionCancel {
            let utiTypes = self.getUtiTypes(draggingInfo: sender)
            let symlinkedFiles = self.symlinkFiles(draggingInfo: sender, filesDirPath: filesDirPath)
            self.startDropLog(utiTypes: utiTypes, symlinkedFiles: symlinkedFiles)
            self.writeUtiData(draggingInfo: sender, utiTypes: utiTypes, zeroDirPath: zeroDirPath)
        }
        if !self.executionCancel {
            self.getPromisedFiles(draggingInfo: sender, promisesDirPath: promisesDirPath)
        }
        
        return true
    }
    
    func getPaths() -> (String, String, String, String, String) {
        let tempDirPath: String = NSTemporaryDirectory() + "se.eberl.droppy" + "/"
        let cacheDirPath: String = tempDirPath + "_cache" + "/"
        let logFilePath: String = cacheDirPath + "droppy.log"
        let zeroDirPath: String = cacheDirPath + "0" + "/"
        let filesDirPath: String = zeroDirPath + "files" + "/"
        let promisesDirPath: String = zeroDirPath + "promises" + "/"
        
        AppState.tempDirPath = tempDirPath
        
        os_log("tempDirPath:     '%@'", log: logDrop, type: .debug, tempDirPath)
        os_log("cacheDirPath:    '%@'", log: logDrop, type: .debug, cacheDirPath)
        os_log("logFilePath:     '%@'", log: logDrop, type: .debug, logFilePath)
        os_log("zeroDirPath:     '%@'", log: logDrop, type: .debug, zeroDirPath)
        os_log("filesDirPath:    '%@'", log: logDrop, type: .debug, filesDirPath)
        os_log("promisesDirPath: '%@'", log: logDrop, type: .debug, promisesDirPath)
        
        // Delete the parent {temp}/_cache directory and recreate its subfolders.
        if isDir(path: cacheDirPath) {
            removeDir(path: cacheDirPath)
        }
        makeDirs(path: filesDirPath)
        makeDirs(path: promisesDirPath)
        
        return (tempDirPath, logFilePath, zeroDirPath, filesDirPath, promisesDirPath)
    }
    
    func getUtiTypes(draggingInfo: NSDraggingInfo) -> [String] {
        var utiTypes: [String] = []
        
        if let types = draggingInfo.draggingPasteboard().types {
            for type in types {
                if self.isUtiType(typeName: type.rawValue) {
                    utiTypes.append(type.rawValue)
                }
            }
        } else {
            os_log("Something is wrong with the passed NSDraggingInfo (types is nil).", log: logDrop, type: .error)
        }

        return utiTypes.sorted()
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
    
    func startDropLog(utiTypes: [String], symlinkedFiles: [String]) {
        os_log("Creating new log file at '%@'", log: logDrop, type: .debug, self.logFilePath)
        do {
            try "".write(to: URL(fileURLWithPath: self.logFilePath), atomically: false, encoding: String.Encoding.utf8)
        } catch let error {
            os_log("%@", log: logDrop, type: .error, error.localizedDescription)
            return
        }
        
        // Write some basic info into it.
        if let thisVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.writeLog(prefix: "DropPy version:           ", lines: [thisVersion])
        } else {
            self.writeLog(prefix: "DropPy version:           ", lines: ["???"])
        }
        if AppState.isLicensed {
            let userDefaults = UserDefaults.standard
            let regLicenseCode: String = userDefaults.string(forKey: UserDefaultStruct.regLicenseCode)!
            let cutStartIndex = regLicenseCode.index(regLicenseCode.startIndex, offsetBy: 0)
            let cutEndIndex = regLicenseCode.index(regLicenseCode.endIndex, offsetBy: -30)
            let regLicenseCodeCut: String = String(regLicenseCode[cutStartIndex...cutEndIndex])
            self.writeLog(prefix: "Registration Status:      ", lines: ["Licensed (\(regLicenseCodeCut)...)"])
        } else {
            if AppState.isInEvaluation {
                self.writeLog(prefix: "Registration Status:      ", lines: ["Unlicensed (Evaluation)"])
            } else {
                self.writeLog(prefix: "Registration Status:      ", lines: ["Unlicensed (Evaluation over)"])
            }
        }
        self.writeLog(prefix: "Bundled droppy-workspace: ", lines: [AppState.bundledWorkspaceVersion])
        self.writeLog(prefix: "Bundled droppy-run:       ", lines: [AppState.bundledRunVersion])
        self.writeLog(prefix: "", lines: [String(repeating: "=", count: 120)])
        self.writeLog(prefix: "Dropped Date/Time:        ", lines: [Date().readable])
        self.writeLog(prefix: "Dropped Object Datatypes: ", lines: utiTypes)
        if symlinkedFiles.count > 0 {
            self.writeLog(prefix: "Dropped Files:            ", lines: symlinkedFiles)
        } else {
            self.writeLog(prefix: "Dropped Files:            ", lines: [""])
        }
    }
    
    func finishDropLog() {
        if let startTime = self.startTime {
            let endTime = DispatchTime.now()
            let nanoTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            self.writeLog(prefix: "Dropped Run Time:         ", lines: [String(format: "%.2f", timeInterval) + "s"])
            self.writeLog(prefix: "", lines: [String(repeating: "=", count: 120)])
        }
    }

    func writeLog(prefix: String, lines: [String]) {
        // The file is guaranteed to exist at that point, it may have content or be empty.
        if self.logFilePath != "" {
            var prefixedLine: String
            if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
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
    }
    
    func symlinkFiles(draggingInfo: NSDraggingInfo, filesDirPath: String) -> [String]{
        os_log("Symlinking files into '%@'", log: logDrop, type: .debug, filesDirPath)
        
        var symlinkedFiles: [String] = []
        
        // Symlink the originally dropped files.
        let fileManager = FileManager.default
        for srcPath in self.getFilePaths(draggingInfo: draggingInfo) {
            let srcURL: URL = URL(fileURLWithPath: srcPath)
            var dstURL: URL = URL(fileURLWithPath: filesDirPath)
            dstURL.appendPathComponent(srcURL.lastPathComponent)
            
            do {
                try fileManager.createSymbolicLink(at: dstURL, withDestinationURL: srcURL)
            } catch {
                os_log("Unable to symlink file '%@'.", log: logDrop, type: .error, srcPath)
            }
            symlinkedFiles.append(srcURL.path)
        }
        
        // Delete all .DS_Store files.
        guard let enumerator: FileManager.DirectoryEnumerator =
            fileManager.enumerator(atPath: filesDirPath) else {
                os_log("Directory not found '%@'.", log: logDrop, type: .error, filesDirPath)
                return symlinkedFiles
        }
        while let element = enumerator.nextObject() as? String {
            let elementPath = filesDirPath + element
            let elementURL: URL = URL(fileURLWithPath: elementPath)
            if elementURL.lastPathComponent == ".DS_Store" {
                do {
                    try fileManager.removeItem(atPath: elementPath)
                } catch let error {
                    os_log("%@", log: logDrop, type: .error, error.localizedDescription)
                }
            }
        }
        
        return symlinkedFiles
    }
    
    func getFilePaths(draggingInfo: NSDraggingInfo) -> [String] {
        // No luck getting this to work with the new "public.file-url" instead of the old "NSFilenamesPboardType"
        // https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html
        if let filePathsArray = draggingInfo.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            if let filePaths = filePathsArray as? [String] {
                return filePaths
            }
        }
        return []
    }
    
    func writeUtiData(draggingInfo: NSDraggingInfo, utiTypes: [String], zeroDirPath: String) {
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
        
        for dataType in utiTypes {
            if let data = draggingInfo.draggingPasteboard().data(forType: NSPasteboard.PasteboardType(rawValue: dataType)) {
                do {
                    var fileExtension: String = "txt"
                    if knownUtiDataTypes[dataType] != nil {
                        fileExtension = knownUtiDataTypes[dataType]!
                    }
                    let dataURL: URL = URL(fileURLWithPath: zeroDirPath + "/" + dataType + "." + fileExtension)
                    try data.write(to: dataURL)
                } catch let error {
                    os_log("%@", log: logDrop, type: .error, error.localizedDescription)
                    os_log("Unable to write '%@' data to file.", log: logDrop, type: .info, dataType)
                }
            }
        }
    }
    
    func getPromisedFiles(draggingInfo: NSDraggingInfo, promisesDirPath: String) {
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
        
        os_log("Requested promised files into '%@'", log: logDrop, type: .debug, promisesDirPath)

        if let filePromises = draggingInfo.draggingPasteboard().readObjects(forClasses: [NSFilePromiseReceiver.self],
                                                                            options: nil) as? [NSFilePromiseReceiver] {
            self.numberOfPromises = filePromises.count
            let promiseOperationQueue: OperationQueue = OperationQueue()
            for filePromise in filePromises {
                filePromise.receivePromisedFiles(atDestination: URL(fileURLWithPath: promisesDirPath),
                                                 operationQueue: promiseOperationQueue,
                                                 reader: self.readExtractedPromises)
            }
        } else {
            self.numberOfPromises = 0
        }
    }
    
    func readExtractedPromises(myUrl: URL, myError: Error?) {
        self.numberOfExtractedPromises += 1
        var logFileContent: String
        
        if myError != nil {
            os_log("%@", log: logDrop, type: .error, myError!.localizedDescription)
            logFileContent = "Error: " + myUrl.path + "(" + myError!.localizedDescription + ")"
            
            // TODO: Mail shows me a timeout error (but seems to copy the file alright). Ignore timeouts?
            // https://stackoverflow.com/questions/11028769/nsurlerrordomain-error-codes-description#11037210
            // I don't think this is my error. Safari support is also sometimes spotty.
            // In any case numberOfExtractedPromises counts up, so even if an error is thrown execution continues.
        } else {
            logFileContent = "Ok:    " + myUrl.path
        }
        
        os_log("Promised file %d/%d '%@'", log: logDrop, type: .debug, self.numberOfExtractedPromises, self.numberOfPromises, myUrl.path)
        
        if self.numberOfExtractedPromises == 1 {
            self.writeLog(prefix: "Dropped Promises:         ", lines: [logFileContent])

        } else {
            self.writeLog(prefix: "                          ", lines: [logFileContent])
        }
        
        if (self.numberOfExtractedPromises == self.numberOfPromises) && !self.executionCancel {
            self.finishDropLog()
            os_log("All promises extracted. Send 'droppingConcluded' notification.", log: logDrop, type: .debug)
            AppState.tempDirPath = self.tempDirPath
            NotificationCenter.default.post(name: .droppingConcluded, object: nil)
        }
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        if (self.numberOfPromises == 0) && !self.executionCancel {
            self.finishDropLog()
            os_log("No promises contained. Send 'droppingConcluded' notification.", log: logDrop, type: .debug)
            AppState.tempDirPath = self.tempDirPath
            NotificationCenter.default.post(name: .droppingConcluded, object: nil)
        }
    }
}
