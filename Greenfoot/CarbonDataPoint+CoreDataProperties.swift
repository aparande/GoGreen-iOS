//
//  CarbonDataPoint+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension CarbonDataPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbonDataPoint> {
        return NSFetchRequest<CarbonDataPoint>(entityName: "CarbonDataPoint")
    }

    @NSManaged public var carbonValue: Double
    @NSManaged public var fid: String?
    @NSManaged public var lastUpdated: NSDate
    @NSManaged public var month: NSDate
    @NSManaged public var rawValue: Double
    @NSManaged public var references: NSSet?
    @NSManaged public var source: CarbonSource
    @NSManaged public var unit: CarbonUnit

}

// MARK: Generated accessors for references
extension CarbonDataPoint {

    @objc(addReferencesObject:)
    @NSManaged public func addToReferences(_ value: CarbonReference)

    @objc(removeReferencesObject:)
    @NSManaged public func removeFromReferences(_ value: CarbonReference)

    @objc(addReferences:)
    @NSManaged public func addToReferences(_ values: NSSet)

    @objc(removeReferences:)
    @NSManaged public func removeFromReferences(_ values: NSSet)

}
