//
//  CarbonDataPoint+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CarbonDataPoint)
public class CarbonDataPoint: NSManagedObject, CoreDataRecord {
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
        
        guard let possibleConversions = self.unit.conversionsTo else {
            print("Couldn't create CarbonDataPoint because Unit has no conversions")
            context.delete(self)
            return nil
        }

        guard let carbonConversion = possibleConversions.first(where: {($0 as? Conversion)?.dest.fid == "direct-default"}) as? Conversion else {
            print("Couldn't create CarbonDataPoint because Unit has no conversion to Carbon")
            context.delete(self)
            return nil
        }
        
        self.carbonValue = carbonConversion.convert(value)
    }
}
