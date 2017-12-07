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
        let application = NSApplication.shared
        application.stopModal()
    }
    
    @IBAction func onPreviousButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Previous")
    }
    
    @IBAction func onNextButton(_ sender: NSButton) {
        self.onPreviousOrNextButton(buttonType: "Next")
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
                let application = NSApplication.shared
                application.stopModal()
                
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
