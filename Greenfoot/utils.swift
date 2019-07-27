//
//  utils.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/26/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

extension Date {
    func toString(withFormat format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
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
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890 ")
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
