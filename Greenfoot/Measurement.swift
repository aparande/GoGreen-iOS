//
//  ComputedDataPoint.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/4/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

protocol Measurement {
    var carbonValue: Double {get set}
    var month: NSDate {get set}
    var rawValue: Double {get set}
    var unit: CarbonUnit {get set}
}

class CarbonValue: Measurement {
    var carbonValue: Double
    var month: NSDate
    var rawValue: Double
    var unit: CarbonUnit
    
    
    init(rawValue: Double, month: NSDate) {
        self.rawValue = rawValue
        self.carbonValue = rawValue
        
        self.month = month
        self.unit = DBManager.shared.carbonUnit
    }
}
