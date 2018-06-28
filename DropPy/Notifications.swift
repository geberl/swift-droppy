//
//  Notifications.swift
//  DropPy
//
//  Created by Günther Eberl on 28.09.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Foundation


extension Notification.Name {
    
    static let workflowsChanged = Notification.Name("workflowsChanged")
    static let reloadWorkflows = Notification.Name("reloadWorkflows")
    static let workflowSelectionChanged = Notification.Name("workflowSelectionChanged")
    static let workflowIdenticalName = Notification.Name("workflowIdenticalName")
    static let workflowNew = Notification.Name("workflowNew")
    static let workflowEdit = Notification.Name("workflowEdit")
    static let workflowDelete = Notification.Name("workflowDelete")
    static let workflowDirOpen = Notification.Name("workflowDirOpen")
    
    static let draggingEnteredOk = Notification.Name("draggingEnteredOk")
    static let draggingEnteredError = Notification.Name("draggingEnteredError")
    static let draggingExited = Notification.Name("draggingExited")
    
    static let droppingStarted = Notification.Name("droppingStarted")
    static let droppingConcluded = Notification.Name("droppingConcluded")
    
    static let executionStatus = Notification.Name("executionStatus")
    static let executionCancel = Notification.Name("executionCancel")
    static let executionFinished = Notification.Name("executionFinished")
    
    static let interpreterNotFound = Notification.Name("interpreterNotFound")
    static let editorNotFound = Notification.Name("editorNotFound")
    static let workspaceNotFound = Notification.Name("workspaceNotFound")
    
    static let loadFileInEditor = Notification.Name("loadFileInEditor")
    static let closeEditor = Notification.Name("closeEditor")
    
    static let switchToPrefTab = Notification.Name("switchToPrefTab")
    static let editorDropped = Notification.Name("editorDropped")
    static let devModeChanged = Notification.Name("devModeChanged")
    
    static let addTask = Notification.Name("addTask")
    static let removeTask = Notification.Name("removeTask")
    static let selectTask = Notification.Name("selectTask")
    static let clearSelection = Notification.Name("clearSelection")
}
