//
//  ViewControllerButtons.swift
//  DropPy
//
//  Created by Günther Eberl on 07.12.17.
//  Copyright © 2017 Günther Eberl. All rights reserved.
//

import Cocoa

class ViewControllerButtons: NSViewController {
    
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setButtonLabels()
    }

    @IBAction func onCancelButton(_ sender: NSButton) {
        self.askCloseWindow()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Previous")
    }
    
    @IBAction func onNextButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Next")
    }
    
    func askCloseWindow() {
        let parentTabViewController = self.getSlideTabViewController()
        if (parentTabViewController != nil) {
            
            // Get the index of the currently active TabViewItem (zero based).
            let selectedTabViewIndex = parentTabViewController!.tabView.indexOfTabViewItem(
                parentTabViewController!.tabView.selectedTabViewItem!)
            
            // Step 1 must be completed at least, otherwise exit app completely.
            
            // TODO this is a bad check. The thing that actually needs to be set is the needed settings.
            // If after that the user clicks back to view one he should still be able to exit without confirmation and without having to complete it again.
            
            if selectedTabViewIndex <= 1 {
                self.confirmEarlyExit()
            } else {
                AppState.initialSetupCompleted = true
                self.closeWindow()
            }
        } else {
            // This should never happen. Close window to be save.
            self.closeWindow()
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
        criticalAlert.icon = NSImage(named: NSImage.Name(rawValue: "error"))
        criticalAlert.beginSheetModal(for: self.view.window!,
                                      completionHandler: self.confiremEarlyExitCompletion)
    }
    
    func confiremEarlyExitCompletion(userChoice: NSApplication.ModalResponse) {
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
                self.closeWindow()
                
            } else {
                
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
    }
    
    func getSlideTabViewController() -> NSTabViewController? {
        // Get the sibling TabViewController via the common parent SplitViewController.
        let parentSplitViewController: NSSplitViewController = self.parent! as! NSSplitViewController
        var parentTabViewController: NSTabViewController? = nil
        
        for viewController in parentSplitViewController.childViewControllers {
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
