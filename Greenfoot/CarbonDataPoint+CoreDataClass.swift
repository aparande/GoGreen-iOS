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
        
    class var fetchAllRequest: NSFetchRequest<Record> {
        let request = NSFetchRequest<CarbonDataPoint>(entityName: "CarbonDataPoint")
        return request
    }
    
    class func all(inContext context: NSManagedObjectContext) throws -> [Record] {
        return try context.fetch(fetchAllRequest)
    }
}
