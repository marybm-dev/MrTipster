//
//  Helper.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

class Helper {
    
    static func getDateFormat() -> NSDateFormatter {
        let dateFormat: NSDateFormatter = NSDateFormatter()
        dateFormat.dateFormat = "MM/dd/yyyy HH:mm:ss"
        
        return dateFormat
    }
    
    static func getBackgroundTime(background: String, foreground: String) {
        let dateFormat = self.getDateFormat()
        
        let lastDate: NSDate = dateFormat.dateFromString(foreground)!
        let todaysDate: NSDate = dateFormat.dateFromString(background)!
        
        let lastDiff: NSTimeInterval = lastDate.timeIntervalSinceNow
        let todaysDiff: NSTimeInterval = todaysDate.timeIntervalSinceNow
        let dateDiff: NSTimeInterval = lastDiff - todaysDiff
        
        let minutes = Int(dateDiff / Double(60))
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(minutes, forKey: "minutes")
        defaults.synchronize()
    }
}