//
//  AppDelegate.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // gets the time difference to count the minutes away
        Helper.getBackgroundTime()
        
        // validates user's time away and resets minutes if needed
        Helper.validateTimeAway()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // saves current timestamp as backgroundTime in defaults
        Helper.setBackgroundTime()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {

        // gets the time difference to count the minutes away
        Helper.getBackgroundTime()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        // validates user's time away and resets minutes if needed
        Helper.validateTimeAway()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        // saves current timestamp as backgroundTime in defaults
        Helper.setBackgroundTime()
    }
}
