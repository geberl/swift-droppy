//
//  ViewControllerEditorText.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log


class ViewControllerEditorText: NSViewController {
    
    var jsonPath: String = ""
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.correctTextViewBehavior()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewControllerEditorText.loadFile),
                                               name: .loadFileInEditor, object: nil)
    }

    @IBOutlet weak var pathLabel: NSTextField!

    @IBOutlet var textView: NSTextView!

    @IBAction func onCancelButton(_ sender: Any) {
        self.replaceEditorContent(with: "")
        NotificationCenter.default.post(name: .closeEditor, object: nil)
    }

    @IBAction func onSaveButton(_ sender: Any) {
        self.saveFile()
        self.replaceEditorContent(with: "")
        NotificationCenter.default.post(name: .reloadWorkflows, object: nil)
        NotificationCenter.default.post(name: .closeEditor, object: nil)
    }

    func setPathLabel(path: String) {
        self.pathLabel.stringValue = path
    }

    func correctTextViewBehavior () {

        if self.textView.isAutomaticQuoteSubstitutionEnabled == true {
            self.textView.toggleAutomaticQuoteSubstitution(self)
        }
        
        if self.textView.isAutomaticDashSubstitutionEnabled == true {
            self.textView.toggleAutomaticDashSubstitution(self)
        }
        
        if self.textView.isAutomaticTextReplacementEnabled == true {
            self.textView.toggleAutomaticTextReplacement(self)
        }
    }
    
    @objc func loadFile(_ notification: Notification) {
        // Extract path String from Notification.
        if let path = notification.userInfo?["path"] as? String {
            self.jsonPath = path
            self.setPathLabel(path: self.jsonPath)
            
            do {
                let jsonUrl = URL(fileURLWithPath: self.jsonPath)
                let jsonContent = try String(contentsOf: jsonUrl, encoding: String.Encoding.utf8)
                self.replaceEditorContent(with: jsonContent)
            } catch {
                os_log("Unable to read file at '%@.", log: logGeneral, type: .error, self.jsonPath)
            }
        }
    }
    
    func replaceEditorContent(with: String) {
        let previousCompleteRange = NSRange(location: 0, length: self.getContent().count)
        
        let newCompleteRange = NSRange(location: 0, length: with.count)
        let newContent = NSMutableAttributedString(string: with)
        if let monoFont = NSFont(name: "Menlo", size: 12) {
            newContent.setAttributes([NSAttributedStringKey.font: monoFont], range: newCompleteRange)
        }
        
        self.textView.insertText(newContent, replacementRange: previousCompleteRange)
    }
    
    func getContent() -> String {
        return self.textView.attributedString().string
    }
    
    func saveFile() {
        do {
            let currentContent: String = self.getContent()
            try currentContent.write(toFile: self.jsonPath, atomically: true, encoding: String.Encoding.utf8)
        } catch let error {
            os_log("%@", log: logGeneral, type: .error, error.localizedDescription)
            os_log("Error writing to file at '%@.", log: logGeneral, type: .info, self.jsonPath)
        }
    }
}
