//
//  CarbonSource+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import UIKit
import CoreData
import Material

@objc(CarbonSource)
public class CarbonSource: NSManagedObject, CoreDataRecord, CoreJsonObject {
    typealias Record = CarbonSource
    
    /**
     Constructs a Carbon Source from a "JSON" dictionary. Note JSON only works with primitives
     */
    required convenience init?(inContext context: NSManagedObjectContext, fromJson json:[String:Any]) {
        self.init(context: context)
        
        guard case let (name as String, sourceCategory as Int, sourceType as Int) =
            (json["name"], json["sourceCategory"], json["sourceType"]) else {
                print("Could not create Carbon Source from json: \(json)")
                context.delete(self)
                return nil
        }
        
        self.name = name
        #warning("Unwrapped optional")
        self.sourceCategory = SourceCategory(rawValue: Int16(sourceCategory))!
        self.sourceType = SourceType(rawValue: Int16(sourceType))!
        
        self.fid = json["fid"] as? String
    }
    
    @nonobjc public class func all(inContext context: NSManagedObjectContext,
                                   fromCategories categories: [SourceCategory]) throws -> [CarbonSource]{
        let request = fetchAllRequest
        
        let categoryVals = categories.map({$0.rawValue})
        
        request.predicate = NSPredicate(format: "%K IN %@", "sourceCategory", categoryVals)
        return try context.fetch(request)
    }
    
    @nonobjc public class func all(inContext context: NSManagedObjectContext,
                                   withTypes types: [SourceType]) throws -> [CarbonSource]{
        let request = fetchAllRequest
        
        let typeVals =  types.map({$0.rawValue})
        
        request.predicate = NSPredicate(format: "%K IN %@", "sourceType", typeVals)
        return try context.fetch(request)
    }
    
    func containsPoint(onDate date: Date) -> Bool {
        return self.points.filter({$0.month.compare(date.truncateToMonth()) == .orderedSame}).count != 0
    }
}

extension CarbonSource {
    @objc
    public enum SourceCategory: Int16 {
        case utility = 0,
            travel = 1,
            direct = 2
        
        var types: [SourceType] {
            switch self {
            case .utility:
                return [.electricity, .gas]
            case .travel:
                return [.odometer]
            default:
                return []
            }
        }
    }
    
    @objc
    public enum SourceType: Int16 {
        case electricity = 0,
            gas = 1,
            odometer = 2,
            direct = 3
        
        var icon: UIImage {
            switch self {
            case .electricity:
                return Icon.electric_white
            case .gas:
                return Icon.fire_white
            case .odometer:
                return Icon.road_white
            case .direct:
                return Icon.smoke_white
            }
        }
        
        var humanName: String {
            switch self {
            case .electricity:
                return "Electric"
            case .gas:
                return "Natural Gas"
            case .odometer:
                return "Car"
            case .direct:
                return "Direct"
            }
        }
    }
    
    @objc
    public enum ConversionType: Int16 {
        case direct = 0,
            derived = 1
    }
}
