//
//  CarbonSource+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CarbonSource)
public class CarbonSource: NSManagedObject {
    @nonobjc private class var fetchAllRequest: NSFetchRequest<CarbonSource> {
        let request = NSFetchRequest<CarbonSource>(entityName: "CarbonSource")
        return request
    }
    
    @nonobjc public class func all(inContext context: NSManagedObjectContext) throws -> [CarbonSource] {
        return try context.fetch(fetchAllRequest)
    }
    
    @nonobjc public class func all(inContext context: NSManagedObjectContext,
                                   fromCategories categories: [SourceCategory] = [.utility, .travel]) throws -> [CarbonSource]{
        let request = fetchAllRequest
        
        let categoryVals = categories.map({$0.rawValue})
        
        request.predicate = NSPredicate(format: "%K IN %@", "sourceCategory", categoryVals)
        return try context.fetch(request)
    }
    
    @nonobjc public class func all(inContext context: NSManagedObjectContext,
                                   withTypes types: [SourceType] = [.electricity, .gas, .odometer]) throws -> [CarbonSource]{
        let request = fetchAllRequest
        
        let typeVals =  types.map({$0.rawValue})
        
        request.predicate = NSPredicate(format: "%K IN %@", "sourceType", typeVals)
        return try context.fetch(request)
    }
}

extension CarbonSource {
    @objc
    public enum SourceCategory: Int16 {
        case utility = 0,
            travel = 1
    }
    
    @objc
    public enum SourceType: Int16 {
        case electricity = 0,
            gas = 1,
            odometer = 2
    }
}
