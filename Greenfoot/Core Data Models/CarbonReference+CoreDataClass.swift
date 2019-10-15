//
//  CarbonReference+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CarbonReference)
public class CarbonReference: CarbonDataPoint {
    required convenience init?(inContext context: NSManagedObjectContext,
                               name: String,
                               source: CarbonSource,
                               unit: CarbonUnit,
                               value: Double,
                               level: Level) {
        self.init(context: context)
        self.name = name
        self.source = source
        self.unit = unit
        self.rawValue = value
        self.level = level
        
        self.month = NSDate()
        self.lastUpdated = NSDate()
        
        guard let possibleConversions = self.unit.conversionsTo else {
            print("Couldn't create CarbonDataPoint because Unit has no conversions")
            context.delete(self)
            return nil
        }
        
        guard let carbonConversion = possibleConversions.first(where: {($0 as? Conversion)?.dest.id == "direct-default"}) as? Conversion else {
            print("Couldn't create CarbonDataPoint because Unit has no conversion to Carbon")
            context.delete(self)
            return nil
        }
        
        self.carbonValue = carbonConversion.convert(value)
    }
    
    required convenience init?(inContext context: NSManagedObjectContext,
                               source: CarbonSource,
                               unit: CarbonUnit,
                               month: NSDate,
                               value: Double) {
        self.init(context: context)
        self.source = source
        self.unit = unit
        self.month = month
        self.lastUpdated = NSDate()
        self.rawValue = value
        self.level = Level.country
        self.name = source.name
        
        guard let possibleConversions = self.unit.conversionsTo else {
            print("Couldn't create CarbonDataPoint because Unit has no conversions")
            context.delete(self)
            return nil
        }
        
        guard let carbonConversion = possibleConversions.first(where: {($0 as? Conversion)?.dest.id == "direct-default"}) as? Conversion else {
            print("Couldn't create CarbonDataPoint because Unit has no conversion to Carbon")
            context.delete(self)
            return nil
        }
        
        self.carbonValue = carbonConversion.convert(value)
    }
}

extension CarbonReference {
    @objc
    public enum Level: Int16 {
        case country = 0,
            state = 1,
            city = 2
    }
}
