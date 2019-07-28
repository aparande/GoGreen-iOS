//
//  CarbonDataPoint+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension CarbonDataPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbonDataPoint> {
        return NSFetchRequest<CarbonDataPoint>(entityName: "CarbonDataPoint")
    }

    @NSManaged public var fid: String?
    @NSManaged public var month: NSDate
    @NSManaged public var rawValue: Double
    @NSManaged public var carbonValue: Double
    @NSManaged public var lastUpdated: NSDate
    @NSManaged public var source: CarbonSource?

}
