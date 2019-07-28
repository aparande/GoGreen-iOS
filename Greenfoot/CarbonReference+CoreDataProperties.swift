//
//  CarbonReference+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension CarbonReference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbonReference> {
        return NSFetchRequest<CarbonReference>(entityName: "CarbonReference")
    }

    @NSManaged public var level: Level
    @NSManaged public var name: String

}
