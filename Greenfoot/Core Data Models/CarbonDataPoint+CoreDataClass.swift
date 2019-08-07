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
    typealias Record = CarbonDataPoint
    
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
        
        guard let carbonConversion = self.unit.carbonConversion else {
            print("Couldn't create CarbonDataPoint because Unit has no conversions")
            context.delete(self)
            return nil
        }
        
        self.carbonValue = carbonConversion.convert(value)
    }
    
    func reference(atLevel level: CarbonReference.Level) -> CarbonReference? {
        return self.references?.first(where: {($0 as? CarbonReference)?.level == level}) as? CarbonReference
    }
}
