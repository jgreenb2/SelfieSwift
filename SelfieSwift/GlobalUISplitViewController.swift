//
//  GlobalUISplitViewController.swift
//  Calculator
//
//  Created by jeff greenberg on 6/17/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//
//
// forces the split view to show the master when collapsed at startup
//
import UIKit

class GlobalUISplitViewController: UISplitViewController, UISplitViewControllerDelegate {
        
    override func viewDidLoad() {
        self.delegate = self
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Regular {
            preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay
        }
        super.viewDidLoad()
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return true
    }    
}
