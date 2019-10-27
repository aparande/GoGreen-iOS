//
//  Conversion+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Conversion)
public class Conversion: NSManagedObject, FirebaseObject, CoreDataRecord {
    typealias Record = Conversion
    
    func convert(_ value: Double) -> Double {
        return value * self.factor
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case factor
        case isPreloaded
        case sourceId
        case destId
    }
    
    public required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContext, let context = decoder.userInfo[contextKey] as? NSManagedObjectContext, let entity = NSEntityDescription.entity(forEntityName: "Conversion", in: context) else {
            fatalError("Failed to decode Carbon Conversion")
        }
        
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.factor = try container.decodeIfPresent(Double.self, forKey: .factor) ?? 0.0
        self.isPreloaded = try container.decodeIfPresent(Bool.self, forKey: .isPreloaded) ?? false
        
        guard let sourceId = try container.decodeIfPresent(String.self, forKey: .sourceId), let destId = try container.decodeIfPresent(String.self, forKey: .destId) else {
            fatalError("Failed to decode Carbon Conversion because source/dest ids missing")
        }
        
        self.source = try CarbonUnit.with(id: sourceId, fromContext: context)!
        self.dest = try CarbonUnit.with(id: destId, fromContext: context)!
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(factor, forKey: .factor)
        try container.encode(isPreloaded, forKey: .isPreloaded)
        try container.encode(source.id, forKey: .sourceId)
        try container.encode(dest.id, forKey: .destId)
    }
}
