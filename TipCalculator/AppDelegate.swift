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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        let dateFormat = Helper.getDateFormat()
        let backgroundTime: String = dateFormat.stringFromDate(NSDate())
        
        // store the current timestamp
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(backgroundTime, forKey: "backgroundTime")
        defaults.synchronize()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        let dateFormat = Helper.getDateFormat()
        let foregroundTime: String = dateFormat.stringFromDate(NSDate())
        let backgroundTime: String = NSUserDefaults.standardUserDefaults().objectForKey("backgroundTime") as! String
        
        // get the time difference to count the minutes away
        Helper.getBackgroundTime(backgroundTime, foreground: foregroundTime)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let minutes = defaults.integerForKey("minutes")
        
        // remove the amount if the time is past 10 minutes
        if minutes > 10 {
            defaults.setDouble(0.0, forKey: "amount")
            defaults.synchronize()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
    }
}