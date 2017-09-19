//
//  Prefs.swift
//  DropPy
//
//  Created by Günther Eberl on 19.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation
import Cocoa


func checkFirstRun() -> Bool {
    // TODO actually detect if this is the first run.
    return false
}


func isKeyPresentInUserDefaults(key: String) -> Bool {
    if UserDefaults.standard.object(forKey: key) == nil {
        return false
    } else {
        return true
    }
}


func validatePrefs() {
    let userDefaults = UserDefaults.standard
    
    // User's DropPy Workspace directory
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.workspacePath) {
        // Start out with default Settings
        // Don't open the Preferences Window, make it as simple and painless and little confusing as possible
        userDefaults.set(UserDefaultStruct.dropCounterDefault, forKey: UserDefaultStruct.dropCounter)
        
        // TODO mine, until I can change this in Preferences to my Development folder
        // userDefaults.set(UserDefaultStruct.workspacePathDefault, forKey: UserDefaultStruct.workspacePath)
        userDefaults.set("/Users/guenther/Development/droppy-workspace", forKey: UserDefaultStruct.workspacePath)
    } else {
        // TODO: Check if the currently set Workspace directory actually still exists, if not open preferences and prompt to change
    }
    
    // Last selected Workflow.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.workflowSelected) {
        userDefaults.set(UserDefaultStruct.workflowSelectedDefault, forKey: UserDefaultStruct.workflowSelected)
    }
    
    // Dev mode.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.devModeEnabled) {
        userDefaults.set(UserDefaultStruct.devModeEnabledDefault, forKey: UserDefaultStruct.devModeEnabled)
    }
    
    // User's external text editor.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorAppPath) {
        userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
    } else {
        // The key exists, now check if the specified editor (app) also still exists on the system.
        if !isDir(path: userDefaults.string(forKey: UserDefaultStruct.editorAppPath)!) {
            userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
            userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
            userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
            userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }
    }
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorIconPath) {
        userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
    } else {
        // The key exists, now check if the specified editor (icns) also still exists on the system.
        if !isFile(path: userDefaults.string(forKey: UserDefaultStruct.editorIconPath)!) {
            userDefaults.set(UserDefaultStruct.editorAppPathDefault, forKey: UserDefaultStruct.editorAppPath)
            userDefaults.set(UserDefaultStruct.editorIconPathDefault, forKey: UserDefaultStruct.editorIconPath)
            userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
            userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
        }
    }
    
    // User's preference for how to edit Workflows.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForWorkflows) {
        userDefaults.set(UserDefaultStruct.editorForWorkflowsDefault, forKey: UserDefaultStruct.editorForWorkflows)
    }
    
    // User's preference for how to edit Tasks.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.editorForTasks) {
        userDefaults.set(UserDefaultStruct.editorForTasksDefault, forKey: UserDefaultStruct.editorForTasks)
    }
    
    // User's Python interpreters and virtual envs.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.interpreters) {
        userDefaults.set(UserDefaultStruct.interpretersDefault, forKey: UserDefaultStruct.interpreters)
    }
    userDefaults.set(UserDefaultStruct.interpreterStockNameDefault, forKey: UserDefaultStruct.interpreterStockName)
    
    // User's update preferences.
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.updateLast) {
        userDefaults.set(UserDefaultStruct.updateLastDefault, forKey: UserDefaultStruct.updateLast)
    }
    if !isKeyPresentInUserDefaults(key: UserDefaultStruct.updateDelta) {
        userDefaults.set(UserDefaultStruct.updateDeltaDefault, forKey: UserDefaultStruct.updateDelta)
    }
    
    // Get the current screen size.
    let resolutionX: Int
    let resolutionY: Int
    (resolutionX, resolutionY) = getScreenResolution()
    let resolutionKeyName: String = String(format: "mainWindowPosAt%dx%d", resolutionX, resolutionY)

    // Apply the window position for this screen size.
    if isKeyPresentInUserDefaults(key: resolutionKeyName) {
        let position: Array = userDefaults.array(forKey: resolutionKeyName)!
        setWindowPosition(positionX: position[0] as! Int, positionY: position[1] as! Int)
    }
}


func getWindowPosition() -> (Int, Int) {
    let window = NSApplication.shared().windows.first
    let positionX: Int =  Int(window!.frame.origin.x)
    let positionY: Int = Int(window!.frame.origin.y)
    // log.debug("getWindowPosition: X: \(positionX), Y: \(positionY)")
    return (positionX, positionY)
}


func setWindowPosition(positionX: Int, positionY: Int) {
    let position = NSPoint(x: positionX, y: positionY)
    guard let window = NSApplication.shared().windows.first else { return }
    window.setFrameOrigin(position)
    // log.debug(String(format: "setWindowPosition: X: %.0f, Y: %.0f", window.frame.origin.x, window.frame.origin.y))
}


func getScreenResolution() -> (Int, Int) {
    let scrn: NSScreen = NSScreen.main()!
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
