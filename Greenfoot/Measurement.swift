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
    
    func display() -> (val: Double, unit: String)
}

extension Measurement {
    func display() -> (val: Double, unit: String) {
        return (self.carbonValue, self.unit.name)
        /*
        guard let superConversions = self.unit.conversionsTo?.filter({ (conv) -> Bool in
            (conv as! Conversion)?.source.id == self.unit.fid
        }) else {
            return (self.carbonValue, self.unit.name)
        }
        
        var optimalVal = self.rawValue
        var unitName = self.unit.name
        
        for conv in superConversions {
            let superVal = conv.convert(self.rawValue)
            if (abs(log(superVal)) < abs(log(optimalVal))) {
                optimalVal = superVal
                unitName = conv.dest.name
            }
        }
        
        
        
        return (optimalVal, unitName) */
    }
}

class CarbonValue: Measurement {
    var carbonValue: Double
    var month: NSDate
    var rawValue: Double
    var unit: CarbonUnit
    
    
    init(rawValue: Double, month: NSDate) {
        self.rawValue = rawValue
        self.carbonValue = rawValue
        self.unit = DBManager.shared.carbonUnit
        self.month = month
    }
    
    init(rawValue: Double) {
        self.month = NSDate()
        self.rawValue = rawValue
        self.carbonValue = rawValue
        self.unit = DBManager.shared.carbonUnit
    }
}

class DerivedValue: Measurement {
    var carbonValue: Double
    var month: NSDate
    var rawValue: Double
    var unit: CarbonUnit
    
    init(rawValue: Double, month: NSDate, unit: CarbonUnit) {
        self.rawValue = rawValue
        self.unit = unit
        self.month = month
        self.carbonValue = self.unit.carbonConversion!.convert(self.rawValue)
    }
}
