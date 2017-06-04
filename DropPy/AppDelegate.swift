//
//  AppDelegate.swift
//  DropPy
//
//  Created by Günther Eberl on 01.04.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import Willow

// Logger configuration
let modifiers: [LogLevel: [LogMessageModifier]] = [.all: [TimestampModifier()]]
let configuration = LoggerConfiguration(modifiers: modifiers)
let log = Logger(configuration: configuration)


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        log.enabled = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        log.enabled = false
    }
    
    func applicationWillBecomeActive(_ notification: Notification) {
        // Reload workflows from workflow dir now to account for added/edited/deleted json files
        NotificationCenter.default.post(name: Notification.Name("appWillBecomeActive"), object: nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
