//
//  GreenDataPoint.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/18/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit
import Material

class GreenDataPoint {
    var value: Double
    var month: Date
    var dataType: String
    var pointType: DataPointType
    var lastUpdated: Date
    var isDeleted: Bool = false
    
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
    
    func delete() {
        isDeleted = true
        lastUpdated = Date()
    }
}

struct GreenAttribute: Codable {
    var value: Int
    var lastUpdated: Date
}

enum DataPointType:String {
    case regular = "REGULAR"
    case energy = "EP"
    case carbon = "CARBON"
    case odometer = "ODOMETER"
}

enum GreenDataType:String {
    case electric = "Electricity"
    case water = "Water"
    case driving = "Driving"
    case gas = "Gas"
    
    static let allValues = [electric, water, driving, gas]
}

struct Colors {
    static let green = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
    static let darkGreen = UIColor(red: 45/255, green: 191/255, blue: 122/255, alpha: 1.0)
    static let red = UIColor(red:231/255, green: 76/255, blue:60/255, alpha:1.0)
    static let blue = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
    static let purple = UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0)
    static let grey = UIColor(red: 127/255, green: 140/255, blue: 141/255, alpha: 1.0)
    
    static let options = [green, red, blue, purple, darkGreen]
}

extension Icon {
    static let logo_white = UIImage(named: "plant")!
    static let electric_white = UIImage(named: "Lightning_Bolt_White")!
    static let water_white = UIImage(named: "Water-Drop")!
    static let smoke_white = UIImage(named: "Smoke")!
    static let info_white = UIImage(named: "Information-256")!
    static let fire_white = UIImage(named: "Fire")!
    static let road_white = UIImage(named: "Road")!
    
    static let chart_green = UIImage(named: "Chart_Green")!
    static let lock = UIImage(named: "Lock")!
    static let person = UIImage(named: "Person")!
    
    static let electric_emblem = UIImage(named:"electric_emblem")!
    static let water_emblem = UIImage(named:"water_emblem")!
    static let leaf_emblem = UIImage(named:"Leaf_Emblem")!
    static let fire_emblem = UIImage(named:"fire_emblem")!
    static let road_emblem = UIImage(named:"road_emblem")!
}

extension Date {
    static func monthFormat(string:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.date(from: string)!
    }
    
    static func monthFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: date)
    }
    
    //Returns the number of months from one date to another
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    
    func nextMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: 1, to: self, wrappingComponents: false) ?? self
    }
}

extension String {
    func removeSpecialChars() -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return String(self.filter {okayChars.contains($0) })
    }
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

