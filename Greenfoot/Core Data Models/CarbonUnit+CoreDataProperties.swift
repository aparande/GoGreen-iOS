//
//  CarbonUnit+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension CarbonUnit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbonUnit> {
        return NSFetchRequest<CarbonUnit>(entityName: "CarbonUnit")
    }
    
    public var carbonConversion: Conversion? {
        return self.conversionsTo?.first(where: {($0 as? Conversion)?.dest.id == "direct-default"}) as? Conversion
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String
    @NSManaged public var sourceType: CarbonSource.SourceType
    @NSManaged public var isDefault: Bool
    @NSManaged public var isPreloaded: Bool
    
    @NSManaged public var associatedPoints: NSSet?
    @NSManaged public var conversionsFrom: NSSet?
    @NSManaged public var conversionsTo: NSSet?
    @NSManaged public var associatedSources: NSSet?
}

// MARK: Generated accessors for associatedPoints
extension CarbonUnit {

    @objc(addAssociatedPointsObject:)
    @NSManaged public func addToAssociatedPoints(_ value: CarbonDataPoint)

    @objc(removeAssociatedPointsObject:)
    @NSManaged public func removeFromAssociatedPoints(_ value: CarbonDataPoint)

    @objc(addAssociatedPoints:)
    @NSManaged public func addToAssociatedPoints(_ values: NSSet)

    @objc(removeAssociatedPoints:)
    @NSManaged public func removeFromAssociatedPoints(_ values: NSSet)

}

// MARK: Generated accessors for conversionsFrom
extension CarbonUnit {

    @objc(addConversionsFromObject:)
    @NSManaged public func addToConversionsFrom(_ value: Conversion)

    @objc(removeConversionsFromObject:)
    @NSManaged public func removeFromConversionsFrom(_ value: Conversion)

    @objc(addConversionsFrom:)
    @NSManaged public func addToConversionsFrom(_ values: NSSet)

    @objc(removeConversionsFrom:)
    @NSManaged public func removeFromConversionsFrom(_ values: NSSet)

}

// MARK: Generated accessors for conversionsTo
extension CarbonUnit {

    @objc(addConversionsToObject:)
    @NSManaged public func addToConversionsTo(_ value: Conversion)

    @objc(removeConversionsToObject:)
    @NSManaged public func removeFromConversionsTo(_ value: Conversion)

    @objc(addConversionsTo:)
    @NSManaged public func addToConversionsTo(_ values: NSSet)

    @objc(removeConversionsTo:)
    @NSManaged public func removeFromConversionsTo(_ values: NSSet)

}

// MARK: Generated accessors for associatedSources
extension CarbonUnit {

    @objc(addAssociatedSourcesObject:)
    @NSManaged public func addToAssociatedSources(_ value: CarbonSource)

    @objc(removeAssociatedSourcesObject:)
    @NSManaged public func removeFromAssociatedSources(_ value: CarbonSource)

    @objc(addAssociatedSources:)
    @NSManaged public func addToAssociatedSources(_ values: NSSet)

    @objc(removeAssociatedSources:)
    @NSManaged public func removeFromAssociatedSources(_ values: NSSet)

}
