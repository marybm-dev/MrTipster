//
//  Variables.swift
//  Tipster
//
//  Created by Mary Martinez on 9/29/16.
//  Copyright © 2016 MMartinez. All rights reserved.
//

import Foundation

struct Variables {
    
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
    
    static let foreignCurrencies = Array(Variables.regionDictionary.keys)
    
    static let tipPercentage: Float = 0.15
    
    static let defaults = UserDefaults.standard
}
