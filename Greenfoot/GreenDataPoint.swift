//
//  GreenDataPoint.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/18/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import Foundation


class GreenDataPoint {
    var value: Double
    var month: Date
    var dataType: String
    var pointType: DataPointType
    var lastUpdated: Date
    
    init(month: Date, value: Double, dataType: String) {
        self.value = value
        self.month = month
        self.dataType = dataType
        pointType = DataPointType.regular
        lastUpdated = Date()
    }
    
    init(month: Date, value: Double, dataType: String, pointType: DataPointType) {
        self.value = value
        self.month = month
        self.dataType = dataType
        self.pointType = pointType
        lastUpdated = Date()
    }
    init(month: Date, value: Double, dataType: String, pointType: DataPointType, lastUpdated: Date) {
        self.value = value
        self.month = month
        self.dataType = dataType
        self.pointType = pointType
        self.lastUpdated = lastUpdated
    }
    init(month: Date, value: Double, dataType: String, lastUpdated: Date) {
        self.value = value
        self.month = month
        self.dataType = dataType
        self.pointType = DataPointType.regular
        self.lastUpdated = lastUpdated
    }
    /**
     Updates value of the GreenDataPoint and sets lastUpdated to today
     - parameter newVal: The new value
     - returns: the old value
     */
    func updateValue(to newVal:Double) -> Double {
        let oldVal = value
        value = newVal
        lastUpdated = Date()
        return oldVal
    }
}

struct GreenAttribute {
    var value: Int
    var lastUpdated: Date
}

enum DataPointType:String {
    case regular = "REGULAR"
    case energy = "EP"
    case carbon = "CARBON"
    case odometer = "ODOMETER"
}
