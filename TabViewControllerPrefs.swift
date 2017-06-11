//
//  TabViewControllerPrefs.swift
//  DropPy
//
//  Created by Günther Eberl on 11.06.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class TabViewControllerPrefs: NSTabViewController {
    
    lazy var originalSizes = [String : NSSize]()

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        
        _ = tabView.selectedTabViewItem
        let originalSize = self.originalSizes[tabViewItem!.label]
        if (originalSize == nil) {
            self.originalSizes[tabViewItem!.label] = (tabViewItem!.view?.frame.size)!
        }
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        
        // Auto resize containing window
        // Source: https://github.com/emiscience/SwiftPrefs
        let window = self.view.window
        if (window != nil) {
            window?.title = tabViewItem!.label
            let size = (self.originalSizes[tabViewItem!.label])!
            let contentFrame = (window?.frameRect(forContentRect: NSMakeRect(0.0, 0.0, size.width, size.height)))!
            var frame = (window?.frame)!
            frame.origin.y = frame.origin.y + (frame.size.height - contentFrame.size.height)
            frame.size.height = contentFrame.size.height;
            frame.size.width = contentFrame.size.width;
            window?.setFrame(frame, display: false, animate: true)
        }

    }
}
