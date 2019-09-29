//
//  Filters.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

protocol Filter {
    func apply(to source:CarbonSource) -> [Measurement]
    init()
}
class DifferenceFilter: Filter {
    private var buffer:[DerivedValue]
    required init() {
        buffer = []
    }
    
    func apply(to source:CarbonSource) -> [Measurement] {
        for i in 0 ..< source.points.count - 1 {
            let firstMonth = source.points[i].month as Date
            let secondMonth = source.points[i+1].month as Date
            
            let difference = source.points[i+1].rawValue - source.points[i].rawValue
            let monthDiff = secondMonth.months(from: firstMonth)
            let step = difference/Double(monthDiff)
            
            buffer.append(DerivedValue(rawValue: step, month: firstMonth as NSDate, unit: source.defaultUnit))
            
            var nextMonth = firstMonth.nextMonth()
            while secondMonth.compare(nextMonth) != ComparisonResult.orderedSame {
                buffer.append(DerivedValue(rawValue: step, month: nextMonth as NSDate, unit: source.defaultUnit))
                nextMonth = nextMonth.nextMonth()
            }
        }

        return buffer
    }
}
