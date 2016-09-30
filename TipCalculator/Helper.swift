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
    
    static func getBackgroundTime(_ background: String, foreground: String) {
        let dateFormat = self.getDateFormat()
        
        let lastDate: Date = dateFormat.date(from: foreground)!
        let todaysDate: Date = dateFormat.date(from: background)!
        
        let lastDiff: TimeInterval = lastDate.timeIntervalSinceNow
        let todaysDiff: TimeInterval = todaysDate.timeIntervalSinceNow
        let dateDiff: TimeInterval = lastDiff - todaysDiff
        
        let minutes = Int(dateDiff / Double(60))
        
        Variables.defaults.set(minutes, forKey: "minutes")
        Variables.defaults.synchronize()
    }

}
