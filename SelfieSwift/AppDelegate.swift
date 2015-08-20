//
//  AppDelegate.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/24/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var splitViewController: UISplitViewController? {
        return window!.rootViewController as? UISplitViewController
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // register for notifications
        let application = UIApplication.sharedApplication()
        var types = UIUserNotificationType.Alert
        types.insert(UIUserNotificationType.Badge)
        types.insert(UIUserNotificationType.Sound)
        let notificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        // manage the split view controller
        // if not done async this causes ios to give the dreaded
        // "unbalanced calls to begin/end appearance transitions" error
        // when the displaymode is Overlay
        delay(0.1) {
            self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay
        }

        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

