//
//  CarbonSource+CoreDataProperties.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData


extension CarbonSource {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CarbonSource> {
        return NSFetchRequest<CarbonSource>(entityName: "CarbonSource")
    }
    
    public var points: [CarbonDataPoint] {
        return self.data?.filter {type(of: $0) == CarbonDataPoint.self} as? [CarbonDataPoint] ?? []
    }
    
    public var lastRecorded: Date? {
        return points.max(by: {$0.month.compare($1.month as Date) == .orderedAscending})?.month as Date?
    }
    
    public var defaultUnit: CarbonUnit {
        if let primary = self.primaryUnit {
            return primary
        } else {
            return try! CarbonUnit.with(id: "\(sourceType.humanName.lowercased())-default", fromContext: DBManager.shared.backgroundContext)!
        }
    }
    
    @NSManaged public var fid: String?
    @NSManaged public var name: String
    @NSManaged public var sourceCategory: SourceCategory
    @NSManaged public var sourceType: SourceType
    @NSManaged public var conversionType: ConversionType
    @NSManaged public var data: NSOrderedSet?
    @NSManaged public var primaryUnit: CarbonUnit?

}

// MARK: Generated accessors for data
extension CarbonSource {

    @objc(insertObject:inDataAtIndex:)
    @NSManaged public func insertIntoData(_ value: CarbonDataPoint, at idx: Int)

    @objc(removeObjectFromDataAtIndex:)
    @NSManaged public func removeFromData(at idx: Int)

    @objc(insertData:atIndexes:)
    @NSManaged public func insertIntoData(_ values: [CarbonDataPoint], at indexes: NSIndexSet)

    @objc(removeDataAtIndexes:)
    @NSManaged public func removeFromData(at indexes: NSIndexSet)

    @objc(replaceObjectInDataAtIndex:withObject:)
    @NSManaged public func replaceData(at idx: Int, with value: CarbonDataPoint)

    @objc(replaceDataAtIndexes:withData:)
    @NSManaged public func replaceData(at indexes: NSIndexSet, with values: [CarbonDataPoint])

    @objc(addDataObject:)
    @NSManaged public func addToData(_ value: CarbonDataPoint)

    @objc(removeDataObject:)
    @NSManaged public func removeFromData(_ value: CarbonDataPoint)

    @objc(addData:)
    @NSManaged public func addToData(_ values: NSOrderedSet)

    @objc(removeData:)
    @NSManaged public func removeFromData(_ values: NSOrderedSet)

}
