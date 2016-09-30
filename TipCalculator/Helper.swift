//
//  Helper.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

class Helper {
    
    static func getDateFormat() -> DateFormatter {
        let dateFormat: DateFormatter = DateFormatter()
        dateFormat.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        return dateFormat
    }
    
    static func getBackgroundTime() {
        let dateFormat = self.getDateFormat()
        let foregroundTime: String = dateFormat.string(from: Date())
        let backgroundTime: String = UserDefaults.standard.object(forKey: "backgroundTime") as! String
        
        let lastDate: Date = dateFormat.date(from: foregroundTime)!
        let todaysDate: Date = dateFormat.date(from: backgroundTime)!
        
        let lastDiff: TimeInterval = lastDate.timeIntervalSinceNow
        let todaysDiff: TimeInterval = todaysDate.timeIntervalSinceNow
        let dateDiff: TimeInterval = lastDiff - todaysDiff
        
        let minutes = Int(dateDiff / Double(60))
        
        Variables.defaults.set(minutes, forKey: "minutes")
        Variables.defaults.synchronize()
    }

    static func setBackgroundTime() {
        let dateFormat = Helper.getDateFormat()
        let backgroundTime: String = dateFormat.string(from: Date())
        
        // store the current timestamp
        Variables.defaults.setValue(backgroundTime, forKey: "backgroundTime")
        Variables.defaults.synchronize()
    }
    
    static func validateTimeAway() {
        let minutes = Variables.defaults.integer(forKey: "minutes")
        
        // remove the amount if the time is past 10 minutes
        if minutes > 10 {
            Variables.defaults.set(0.0, forKey: "amount")
            Variables.defaults.synchronize()
        }
    }
}
