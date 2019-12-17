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
    typealias Record = CarbonReference
    private enum CodingKeys: String, CodingKey {
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
        case level
        case name
    }
    
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
    
    public required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContext,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "CarbonReference", in: context)
            else {
            fatalError("Failed to decode Carbon Reference")
        }
        
        guard let sourceKey = CodingUserInfoKey.source,
            let source = decoder.userInfo[sourceKey] as? CarbonSource
            else {
            fatalError("Failed to decode Carbon Reference")
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.month = try container.decode(Date.self, forKey: .month) as NSDate
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated) as NSDate
        self.rawValue = try container.decode(Double.self, forKey: .rawValue)
        self.carbonValue = try container.decode(Double.self, forKey: .carbonValue)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.level = try CarbonReference.Level(rawValue: container.decodeIfPresent(Int16.self, forKey: .level) ?? 0) ?? .country
        
        self.source = source
        self.unit = self.source.defaultUnit
    }
    
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(month as Date, forKey: .month)
        try container.encode(lastUpdated as Date, forKey: .lastUpdated)
        try container.encode(rawValue, forKey: .rawValue)
        try container.encode(carbonValue, forKey: .carbonValue)
        try container.encode(source.sourceType.rawValue, forKey: .sourceType)
        try container.encode(level.rawValue, forKey: .level)
        try container.encode(name, forKey: .name)
        
        guard let userIdKey = CodingUserInfoKey.userId, let userId = encoder.userInfo[userIdKey] as? String else {
            fatalError("Failed to encode carbon source")
        }
        
        try container.encode(userId, forKey: .userId)
    }
    
    static var fetchAllRequest: NSFetchRequest<CarbonReference> {
        get {
            let request = NSFetchRequest<CarbonReference>(entityName: String(describing: CarbonReference.self))
            return request
        }
    }
    
    static func with(id: String, fromContext context: NSManagedObjectContext) throws -> CarbonReference? {
        let fetchRequest = fetchAllRequest
        fetchRequest.predicate = NSPredicate(format: "%K = %@", "id", id)
        return try context.fetch(fetchRequest).first
    }
    
    static func createIfUnique(inContext context: NSManagedObjectContext, withData data: [String:Any]) -> CarbonReference? {
        var refData = data
        guard let id = data["id"] as? String else { return nil }
        guard let source = refData.removeValue(forKey: "source") as? CarbonSource else { return nil }
        
        do {
            let record = try self.with(id: id, fromContext: context)
            if let _ = record {
                return record!
            }
        } catch {
            //Do Nothing
        }
        
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = context
        decoder.userInfo[CodingUserInfoKey.source!] = source
        decoder.dateDecodingStrategy = .secondsSince1970
        
        guard let json = try? JSONSerialization.data(withJSONObject: refData, options: .prettyPrinted) else { return nil }
        guard let newObj = try? decoder.decode(CarbonReference.self, from: json) else { return nil }
        return newObj
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
