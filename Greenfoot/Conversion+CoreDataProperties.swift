//
//  Conversion+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension Conversion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversion> {
        return NSFetchRequest<Conversion>(entityName: "Conversion")
    }

    @NSManaged public var fid: String?
    @NSManaged public var factor: Double
    @NSManaged public var source: Unit
    @NSManaged public var dest: Unit

}
