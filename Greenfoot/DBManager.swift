//
//  DBManager.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DBManager {
    
    let persistentContainer: NSPersistentContainer
    let defaults: UserDefaults
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    static let shared: DBManager = DBManager()
    
    var carbonUnit: CarbonUnit!
    
    init(container: NSPersistentContainer, defaults: UserDefaults) {
        self.persistentContainer = container
        self.defaults = defaults
        
        if !self.defaults.bool(forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS) {
            self.loadDefaults()
            self.defaults.set(true, forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS)
        }
        
        carbonUnit = try! CarbonUnit.with(id: "direct-default", fromContext: self.backgroundContext)!
    }
    
    private convenience init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Can't get shared app delegate")
        }
        
        self.init(container: appDelegate.persistentContainer, defaults: UserDefaults.standard)
    }
    
    func save() {
        if backgroundContext.hasChanges {
            do {
                try backgroundContext.save()
            } catch {
                let error = error as NSError
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func createCarbonSource(name:String, category: CarbonSource.SourceCategory, type: CarbonSource.SourceType, unit: CarbonUnit) -> CarbonSource {
        let source = CarbonSource(context: backgroundContext)
        source.name = name
        source.sourceCategory = category
        source.sourceType = type
        source.primaryUnit = unit
        
        if source.sourceType == .odometer {
            source.conversionType = .derived
        } else {
            source.conversionType = .direct
        }
        
        self.save()
        return source
    }
    
    func createCarbonPoint(_ value: Double, on date: Date, withUnit unit: CarbonUnit, in source: CarbonSource) throws {
        if source.containsPoint(onDate: date) {
            throw CoreDataError.duplicateError
        }
        
        guard let point = CarbonDataPoint(inContext: self.backgroundContext, source: source, unit: unit, month: date as NSDate, value: value) else { return }
        source.addToData(point)
        self.save()
    }
    
    func createUnit(named name: String, conversionToCO2 conv: Double, forSourceType sourceType: CarbonSource.SourceType) -> CarbonUnit {
        let unit = CarbonUnit(context: self.backgroundContext)
        unit.id = UUID().uuidString
        unit.sourceType = sourceType
        unit.name = name
        
        let conversion = Conversion(context: self.backgroundContext)
        conversion.source = unit
        conversion.dest = carbonUnit
        conversion.factor = conv
        
        self.save()
        
        return unit
    }
}

enum CoreDataError: Error {
    case fetchError
    case duplicateError
}
