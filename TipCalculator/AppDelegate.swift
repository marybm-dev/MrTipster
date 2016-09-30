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
    let defaults = UserDefaults.standard

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        let dateFormat = Helper.getDateFormat()
        let backgroundTime: String = dateFormat.string(from: Date())
        
        // store the current timestamp
        defaults.setValue(backgroundTime, forKey: "backgroundTime")
        defaults.synchronize()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        let dateFormat = Helper.getDateFormat()
        let foregroundTime: String = dateFormat.string(from: Date())
        let backgroundTime: String = UserDefaults.standard.object(forKey: "backgroundTime") as! String
        
        // get the time difference to count the minutes away
        Helper.getBackgroundTime(backgroundTime, foreground: foregroundTime)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let minutes = defaults.integer(forKey: "minutes")
        
        // remove the amount if the time is past 10 minutes
        if minutes > 10 {
            defaults.set(0.0, forKey: "amount")
            defaults.synchronize()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
}
