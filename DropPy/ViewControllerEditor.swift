//
//  ViewControllerEditor.swift
//  DropPy
//
//  Created by Günther Eberl on 17.08.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerEditor: NSViewController {
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.setPathLabel()
        self.correctTextViewBehavior()
        self.loadFile()
    }

    @IBOutlet weak var pathLabel: NSTextField!
    
    @IBOutlet var textView: NSTextView!
    
    @IBAction func onCancelButton(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("closeEditor"), object: nil)
    }
    
    @IBAction func onSaveButton(_ sender: Any) {
        self.saveFile()
        NotificationCenter.default.post(name: Notification.Name("closeEditor"), object: nil)
    }
    
    func setPathLabel () {
        // TODO use actual file path
        self.pathLabel.stringValue = "/abc/def/file.json"
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
    
    func loadFile() {
        // TODO use actual file content
        let completeRange = NSRange(location: 0, length: "(file content here)".characters.count)
        self.textView.insertText("abc", replacementRange: completeRange)
    }
    
    func saveFile() {
        // TODO
        log.debug("Save json file now.")
    }
}
