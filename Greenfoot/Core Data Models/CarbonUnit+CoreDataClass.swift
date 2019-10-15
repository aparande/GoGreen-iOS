//
//  Unit+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CarbonUnit)
public class CarbonUnit: NSManagedObject, CoreDataRecord, FirebaseObject {
    typealias Record = CarbonUnit
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sourceType
        case isDefault
        case isPreloaded
    }
    
    required convenience init?(inContext context: NSManagedObjectContext, fromJson json: [String : Any]) {
        self.init(context: context)
        
        self.id = json["id"] as? String
        
        guard case let (name as String, sourceType as Int) =
            (json["name"], json["sourceType"]) else {
                print("Could not create Unit from json: \(json)")
                context.delete(self)
                return nil
        }
        
        self.name = name
        #warning("Unwrapped optional")
        self.sourceType = CarbonSource.SourceType(rawValue: Int16(sourceType))!
    }
    
    public required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextKey] as? NSManagedObjectContext, let entity = NSEntityDescription.entity(forEntityName: "CarbonUnit", in: context) else {
            fatalError("Failed to decode Carbon Unit")
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.sourceType = try CarbonSource.SourceType(rawValue: container.decodeIfPresent(Int16.self, forKey: .sourceType) ?? 0) ?? CarbonSource.SourceType.direct
        self.isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
        self.isPreloaded = try container.decodeIfPresent(Bool.self, forKey: .isPreloaded) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(sourceType.rawValue, forKey: .sourceType)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(isPreloaded, forKey: .isPreloaded)
    }
    
    static func with(id: String, fromContext context: NSManagedObjectContext) throws -> Record? {
        let fetchRequest = fetchAllRequest
        fetchRequest.predicate = NSPredicate(format: "%K = %@", "id", id)
        return try context.fetch(fetchRequest).first
    }
}
