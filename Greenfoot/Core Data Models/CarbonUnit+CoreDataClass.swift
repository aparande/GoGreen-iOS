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
public class CarbonUnit: NSManagedObject, CoreDataRecord, CoreJsonObject {
    typealias Record = CarbonUnit
    
    required convenience init?(inContext context: NSManagedObjectContext, fromJson json: [String : Any]) {
        self.init(context: context)
        
        self.fid = json["fid"] as? String
        
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
}
