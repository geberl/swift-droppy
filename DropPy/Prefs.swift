//
//  Prefs.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import Cocoa
import os.log


struct UserDefaultStruct {
    // This struct needs to contain TWO static vars for each plist record.
    // One to set the KEY's name (type always String) and one to set the default VALUE (type accordingly).
    
    // The following variables are validated on app start and can afterwards safely be force unwrapped.
    
    static var workspacePath: String = "workspacePath"
    static var workspacePathDefault: String = NSHomeDirectory() + "/" + "DropPy" + "/"
    
    static var workflowSelected: String = "workflowSelected"
    static var workflowSelectedDefault: String? = nil
    
    static var devModeEnabled: String = "devModeEnabled"
    static var devModeEnabledDefault: Bool = false
    
    static var editorAppPath: String = "editorAppPath"
    static var editorAppPathDefault: String = ""
    
    static var editorIconPath: String = "editorIconPath"
    static var editorIconPathDefault: String = ""
    
    static var editorForWorkflows: String = "editorForWorkflows"
    static var editorForWorkflowsDefault: String = "Internal text editor" // TODO: Set "Internal Workflow editor" as default once done.
    
    static var editorForTasks: String = "editorForTasks"
    static var editorForTasksDefault: String = "Internal text editor"
    
    static var interpreters: String = "interpreters"
    static var interpretersDefault: Dictionary = ["macOS pre-installed": ["executable": "/usr/bin/python", "arguments": "-B"]]
    
    static var updateLast: String = "updateLast"
    static var updateLastDefault: Date = Date()
    
    static var updateDelta: String = "updateDelta"
    static var updateDeltaDefault: Int = 60 * 60 * 24 * 7  // a week in seconds, maxint of UInt64 is much higher.
    
    static var trialStartDate: String = "trialStartDate"
    static var trialStartDateDefault: Date = Date()
    
    static var trialStartHash: String = "trialStartHash"
    static var trialStartHashDefault: String = ""  // wrong on purpose to invalidate on tampering.
    
    // The following values have no defaults and are not guaranteed to be present. No force unwrapping here!
    // They are only set on valid registering.
    
    static var regName: String = "regName"
    static var regCompany: String = "regCompany"
    static var regEmail: String = "regEmail"
    static var regLicenseCode: String = "regLicenseCode"
}


func isFirstRun() -> Bool {
    // Check all relevant keys independently. As soon as one is found it can't be the app's first run.
    if isKeyPresentInUserDefaults(key: "workspacePath") { return false }
    if isKeyPresentInUserDefaults(key: "workflowSelected") { return false }
    if isKeyPresentInUserDefaults(key: "devModeEnabled") { return false }
    if isKeyPresentInUserDefaults(key: "editorAppPath") { return false }
    if isKeyPresentInUserDefaults(key: "editorIconPath") { return false }
    if isKeyPresentInUserDefaults(key: "editorForWorkflows") { return false }
    if isKeyPresentInUserDefaults(key: "editorForTasks") { return false }
    if isKeyPresentInUserDefaults(key: "interpreters") { return false }
    if isKeyPresentInUserDefaults(key: "updateLast") { return false }
    if isKeyPresentInUserDefaults(key: "updateDelta") { return false }
    if isKeyPresentInUserDefaults(key: "trialStartDate") { return false }
    if isKeyPresentInUserDefaults(key: "trialStartHash") { return false }
    return true
}


func isKeyPresentInUserDefaults(key: String) -> Bool {
    if UserDefaults.standard.object(forKey: key) == nil {
        return false
    } else {
        return true
    }
}


func reapplyPrefs() {
    os_log("Validating preferences.", log: logGeneral, type: .debug)
    
    let userDefaults = UserDefaults.standard
    
    // No check if these directory/files actually exists here, this has to be checked before each usage.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.workspacePath) {
        userDefaults.set(UserDefaultStruct.workspacePathDefault, forKey: UserDefaultStruct.workspacePath)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.workflowSelected) {
        userDefaults.set(UserDefaultStruct.workflowSelectedDefault, forKey: UserDefaultStruct.workflowSelected)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.devModeEnabled) {
        userDefaults.set(UserDefaultStruct.devModeEnabledDefault, forKey: UserDefaultStruct.devModeEnabled)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorAppPath) {
        userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorIconPath) {
        userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForWorkflows) {
        userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForTasks) {
        userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.interpreters) {
        userDefaults.set(UserDefaultStruct.interpretersDefault, forKey: UserDefaultStruct.interpreters)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.updateLast) {
        userDefaults.set(UserDefaultStruct.updateLastDefault, forKey: UserDefaultStruct.updateLast)
    }
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.updateDelta) {
        userDefaults.set(UserDefaultStruct.updateDeltaDefault, forKey: UserDefaultStruct.updateDelta)
    }
    
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.trialStartDate) {
        userDefaults.set(UserDefaultStruct.trialStartDateDefault, forKey: UserDefaultStruct.trialStartDate)
    }
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.trialStartHash) {
        userDefaults.set(UserDefaultStruct.trialStartHashDefault, forKey: UserDefaultStruct.trialStartHash)
    }
}

func loadWindowPosition() {
    let userDefaults = UserDefaults.standard
    
    // Get the current screen size.
    let resolutionX: Int
    let resolutionY: Int
    (resolutionX, resolutionY) = getScreenResolution()
    let resolutionKeyName: String = String(format: "mainWindowPosAt%dx%d", resolutionX, resolutionY)

    // Apply the window position for this screen size, if present.
    if isKeyPresentInUserDefaults(key: resolutionKeyName) {
        let position: Array = userDefaults.array(forKey: resolutionKeyName)!
        setWindowPosition(positionX: position[0] as! Int, positionY: position[1] as! Int)
    }
}


func getWindowPosition() -> (Int, Int) {
    let window = NSApplication.shared.windows.first
    let positionX: Int =  Int(window!.frame.origin.x)
    let positionY: Int = Int(window!.frame.origin.y)
    // log.debug("getWindowPosition: X: \(positionX), Y: \(positionY)")
    return (positionX, positionY)
}


func setWindowPosition(positionX: Int, positionY: Int) {
    let position = NSPoint(x: positionX, y: positionY)
    guard let window = NSApplication.shared.windows.first else { return }
    window.setFrameOrigin(position)
    // log.debug(String(format: "setWindowPosition: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
}


func getScreenResolution() -> (Int, Int) {
    let scrn: NSScreen = NSScreen.main!
    let rect: NSRect = scrn.frame
    let height = rect.size.height
    let width = rect.size.width
    // log.debug(String(format: "getScreenResolution: X: %.0f, Y: %.0f", height, width))
    return (Int(height), Int(width))
}


func saveWindowPosition() {
    // Get the current screen size.
    let resolutionX: Int
    let resolutionY: Int
    (resolutionX, resolutionY) = getScreenResolution()
    let resolutionKeyName: String = String(format: "mainWindowPosAt%dx%d", resolutionX, resolutionY)

    // Get the current window position.
    let positionX: Int
    let positionY: Int
    (positionX, positionY) = getWindowPosition()
    
    // Save the window position for this screen size.
    UserDefaults.standard.set([positionX, positionY], forKey: resolutionKeyName)
}


func checkWorkspaceInfo() -> String? {
    let userDefaults = UserDefaults.standard
    
    if userDefaults.string(forKey: UserDefaultStruct.workspacePath) == nil {
        // Key for workspacePath doesn't exist in UserDefaults any more. Set to default and continue.
        userDefaults.set(UserDefaultStruct.workspacePathDefault, forKey: UserDefaultStruct.workspacePath)
    }
    let workspacePath = userDefaults.string(forKey: UserDefaultStruct.workspacePath)!
    
    if isDir(path: workspacePath) {
        if !isDir(path: workspacePath + "/" + "Images") {
            makeDirs(path: workspacePath + "/" + "Images")
        }
        if !isDir(path: workspacePath + "/" + "Tasks") {
            makeDirs(path: workspacePath + "/" + "Tasks")
        }
        if !isDir(path: workspacePath + "/" + "Workflows") {
            makeDirs(path: workspacePath + "/" + "Workflows")
        }
        return workspacePath + "/"
    }
    
    NotificationCenter.default.post(name: .workspaceNotFound, object: nil)
    return nil
}
