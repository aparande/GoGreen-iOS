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
public class CarbonDataPoint: NSManagedObject, CoreDataRecord, FirebaseObject {
    typealias Record = CarbonDataPoint
    
    enum CodingKeys: String, CodingKey {
        case id
        case sourceId
        case unitId
        case month
        case lastUpdated
        case rawValue
        case carbonValue
        case userId
        case sourceType
        case sourceCategory
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
        self.carbonValue = 0
        
        if source.conversionType == .direct {
            guard let carbonConversion = self.unit.carbonConversion else {
                print("Couldn't create CarbonDataPoint because Unit has no conversions")
                context.delete(self)
                return nil
            }
            
            self.carbonValue = carbonConversion.convert(value)
        }
    }
    
    public required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextKey] as? NSManagedObjectContext, let entity = NSEntityDescription.entity(forEntityName: "CarbonDataPoint", in: context) else {
            fatalError("Failed to decode Carbon Data Point")
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.month = try container.decode(Date.self, forKey: .month) as NSDate
        self.lastUpdated = try container.decode(Date.self, forKey: .month) as NSDate
        self.rawValue = try container.decode(Double.self, forKey: .rawValue)
        self.carbonValue = try container.decode(Double.self, forKey: .carbonValue)
        
        let sourceId = try container.decode(String.self, forKey: .sourceId)
        guard let source = try CarbonSource.with(id: sourceId, fromContext: context) else {
            fatalError("Failed to decode Carbon Data Point Source")
        }
        self.source = source
        
        let unitId = try container.decode(String.self, forKey: .unitId)
        self.unit = try CarbonUnit.with(id: unitId, fromContext: context) ?? self.source.defaultUnit
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(month as Date, forKey: .month)
        try container.encode(lastUpdated as Date, forKey: .lastUpdated)
        try container.encode(rawValue, forKey: .rawValue)
        try container.encode(carbonValue, forKey: .carbonValue)
        try container.encode(source.id, forKey: .sourceId)
        try container.encode(unit.id, forKey: .unitId)
        try container.encode(source.sourceType.rawValue, forKey: .sourceType)
        try container.encode(source.sourceCategory.rawValue, forKey: .sourceCategory)
        
        guard let userIdKey = CodingUserInfoKey.userId, let userId = encoder.userInfo[userIdKey] as? String else {
            fatalError("Failed to encode carbon source")
        }
        
        try container.encode(userId, forKey: .userId)
    }
    
    func reference(atLevel level: CarbonReference.Level) -> CarbonReference? {
        return self.references?.first(where: {($0 as? CarbonReference)?.level == level}) as? CarbonReference
    }
}
