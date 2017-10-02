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
    
    static let draggingEnteredOk = Notification.Name("draggingEnteredOk")
    static let draggingEnteredNoWorkflowSelected = Notification.Name("draggingEnteredNoWorkflowSelected")
    static let draggingExited = Notification.Name("draggingExited")
    static let droppingOk = Notification.Name("droppingOk")
    
    static let executionStatus = Notification.Name("executionStatus")
    static let executionCancel = Notification.Name("executionCancel")
    static let executionFinished = Notification.Name("executionFinished")
    
    static let interpreterNotFound = Notification.Name("interpreterNotFound")
    static let editorNotFound = Notification.Name("editorNotFound")
    static let workspaceNotFound = Notification.Name("workspaceNotFound")
    
    static let reopenPurchaseSheet = Notification.Name("reopenPurchaseSheet")
    static let closeRegistration = Notification.Name("closeRegistration")
    
    static let updateError = Notification.Name("updateError")
    static let updateNotAvailable = Notification.Name("updateNotAvailable")
    static let updateAvailable = Notification.Name("updateAvailable")
    
    static let loadFileInEditor = Notification.Name("loadFileInEditor")
    static let closeEditor = Notification.Name("closeEditor")
    
    static let switchToPrefTab = Notification.Name("switchToPrefTab")
    static let editorDropped = Notification.Name("editorDropped")
}