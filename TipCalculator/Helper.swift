//
//  Helper.swift
//  TipCalculator
//
//  Created by Mary Martinez on 3/21/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

class Helper {
    
    enum Region: String {
        case USA = "USA"
        case EU = "EU"
        case UK = "UK"
        case Japan = "Japan"
        case India =  "India"
    }
    
    static let regionDictionary: [String : Region] = [
        "$" : .USA,
        "€" : .EU,
        "£" : .UK,
        "¥" : .Japan,
        "₹" : .India
    ]
    
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
        
        let defaults = UserDefaults.standard
        defaults.set(minutes, forKey: "minutes")
        defaults.synchronize()
    }
    
    static func saveSettings(_ percent: Double?, _ controlIndex: Int?, _ currency : String?) {
        let defaults = UserDefaults.standard
        
        if let defaultPercent = percent {
            defaults.set(defaultPercent, forKey: "percent")
        }
        
        if let selectedIndex = controlIndex {
            defaults.set(selectedIndex, forKey: "controlIndex")
        }
        
        if let defaultCurrency = currency {
            defaults.set(defaultCurrency, forKey: "currency")
        }
        
        defaults.synchronize()
    }
}
