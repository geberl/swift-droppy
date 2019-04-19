//
//  ViewControllerButtons.swift
//  DropPy
//
//  Created by Günther Eberl on 07.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa
import os.log

class ViewControllerButtons: NSViewController {
    
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setButtonLabels()
    }

    @IBAction func onCancelButton(_ sender: NSButton) {
        self.checkSetupCompleted()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Previous")
    }
    
    @IBAction func onNextButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Next")
    }
    
    func checkExtractWorkspace() -> Bool {
        let parentTabViewController = self.getSlideTabViewController()
        if (parentTabViewController != nil) {
            
            // Get the ViewController that contains the checkbox.
            var workspaceViewController: ViewControllerWorkspaceSetup? = nil
            for viewController in parentTabViewController!.children {
                if viewController.title! == "Workspace Setup" {
                    workspaceViewController = viewController as? ViewControllerWorkspaceSetup
                    break
                }
            }
            
            // Get the checkbox.
            if (workspaceViewController != nil) {
                return workspaceViewController!.getDefaultContentCheckboxValue()
            }
        }
        
        return false  // default don't extract, however this should never be reachable.
    }
    
    func checkSetupCompleted() {
        // Check if a workspacePath was set in the UserDefaults. This is the only condition that needs to be guaranteed.
        if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {

            // Create directory structure (this is non-destructive, can always be called).
            createWorkspaceDirStructure(workspacePath: workspacePath)
            
            // Get the status of the "Extract default content" checkbox and extract that content.
            let extractWorkspace: Bool = self.checkExtractWorkspace()
            if extractWorkspace {
                extractBundledWorkspace(workspacePath: workspacePath)
            } else {
            }

            AppState.initialSetupCompleted = true
            self.closeWindow()
        } else {
            self.confirmEarlyExit()
        }
    }

    func closeWindow() {
        let application = NSApplication.shared
        application.stopModal()
    }
    
    func confirmEarlyExit() {
        let criticalAlert = NSAlert()
        criticalAlert.showsHelp = false
        criticalAlert.messageText = "Initial Setup incomplete"
        criticalAlert.informativeText = "Without completing the initial setup DropPy can't start.\n\n"
        criticalAlert.informativeText  += "This assistant will be shown again next time."
        criticalAlert.addButton(withTitle: "Cancel")
        criticalAlert.addButton(withTitle: "Exit DropPy")
        criticalAlert.layout()
        criticalAlert.alertStyle = NSAlert.Style.critical
        criticalAlert.icon = NSImage(named: "error")
        criticalAlert.beginSheetModal(for: self.view.window!,
                                      completionHandler: self.confirmEarlyExitCompletion)
    }
    
    func confirmEarlyExitCompletion(userChoice: NSApplication.ModalResponse) {
        if userChoice == NSApplication.ModalResponse.alertSecondButtonReturn {
            AppState.initialSetupCompleted = false
            self.closeWindow()
        }
    }
    
    func onPreviousOrNextButton(buttonType: String) {
        let parentTabViewController = self.getSlideTabViewController()
        if (parentTabViewController != nil) {
            
            // Get the index of the currently active TabViewItem (zero based).
            let selectedTabViewIndex = parentTabViewController!.tabView.indexOfTabViewItem(
                parentTabViewController!.tabView.selectedTabViewItem!)

            // Get the total number of TabViewItems.
            let numberOfTabViewItems = parentTabViewController!.tabView.numberOfTabViewItems
            
            // Determine if this is the last TabViewItem and user clicked on "Next".
            if (selectedTabViewIndex + 1 == numberOfTabViewItems) && (buttonType == "Next") {
                // Close the window.
                self.checkSetupCompleted()
                return  // make sure to not execute anything below, indexes may run over (a timing thing)
            }
            
            // Check if the user clicked past the view where the workspaceDir settings are displayed.
            if (selectedTabViewIndex + 1 == 2) && (buttonType == "Next") {
                // Check if a custom key was set.
                if let workspacePath: String = userDefaults.string(forKey: UserDefaultStruct.workspacePath) {
                    os_log("Custom workspacePath: '%@'", log: logGeneral, type: .debug, workspacePath)
                }
                // No key was set, assume user is ok with the defaults.
                else {
                    os_log("Assuming default workspacePath: '%@'", log: logGeneral, type: .debug,
                           UserDefaultStruct.workspacePathDefault)
                    self.userDefaults.set(UserDefaultStruct.workspacePathDefault,
                                          forKey: UserDefaultStruct.workspacePath)
                }
            }
            
            // Adjust the animation and switch to the previous/next TabViewItem.
            if (buttonType == "Previous") {
                parentTabViewController!.transitionOptions = [NSViewController.TransitionOptions.slideBackward,
                                                              NSViewController.TransitionOptions.crossfade]
                parentTabViewController!.tabView.selectTabViewItem(at: selectedTabViewIndex - 1)
            }
            else if (buttonType == "Next") {
                parentTabViewController!.transitionOptions = [NSViewController.TransitionOptions.slideForward,
                                                              NSViewController.TransitionOptions.crossfade]
                parentTabViewController!.tabView.selectTabViewItem(at: selectedTabViewIndex + 1)
            }
            
            // Adjust the text on the buttons.
            self.setButtonLabels()
        }
    }
    
    func getSlideTabViewController() -> NSTabViewController? {
        // Get the sibling TabViewController via the common parent SplitViewController.
        let parentSplitViewController: NSSplitViewController = self.parent! as! NSSplitViewController
        var parentTabViewController: NSTabViewController? = nil
        
        for viewController in parentSplitViewController.children {
            if viewController.title! == "Tabs" {
                parentTabViewController = viewController as? NSTabViewController
                return parentTabViewController
            }
        }
        return nil
    }
    
    func setButtonLabels() {
        let parentTabViewController = self.getSlideTabViewController()
        if (parentTabViewController != nil) {
            
            // Get the index of the currently active TabViewItem (zero based).
            let selectedTabViewIndex = parentTabViewController!.tabView.indexOfTabViewItem(
                parentTabViewController!.tabView.selectedTabViewItem!)
            
            // Get the total number of TabViewItems.
            let numberOfTabViewItems = parentTabViewController!.tabView.numberOfTabViewItems
            
            // First TabViewItem.
            if selectedTabViewIndex == 0 {
                cancelButton.isEnabled = true
                previousButton.isEnabled = false
                nextButton.title = "Next"
            }
            // Last TabViewItem.
            else if selectedTabViewIndex == numberOfTabViewItems - 1 {
                cancelButton.isEnabled = false
                previousButton.isEnabled = true
                nextButton.title = "Finish"
            }
            // All other TabViewItems.
            else {
                cancelButton.isEnabled = true
                previousButton.isEnabled = true
                nextButton.title = "Next"
            }
        }
    }
}
