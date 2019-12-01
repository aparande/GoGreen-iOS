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
    
    static let DEFAULTS_LOADED = NSNotification.Name("firebase_defaults_loaded")
    
    let persistentContainer: NSPersistentContainer
    let defaults: UserDefaults
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    static let shared: DBManager = DBManager()
    
    var carbonUnit: CarbonUnit!
    var loadedFromFirebase: Bool
    
    init(container: NSPersistentContainer, defaults: UserDefaults) {
        self.persistentContainer = container
        self.defaults = defaults
        self.loadedFromFirebase = false
        
        if self.defaults.bool(forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS) {
            print("Firebase Defaults already loaded")
            self.loadedFromFirebase = true
            carbonUnit = try! CarbonUnit.defaultUnit(forSourceType: .direct, inContext: self.backgroundContext)
            NotificationCenter.default.post(name: DBManager.DEFAULTS_LOADED, object: nil)
        } else {
            self.loadDefaults()
        }
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
        
        FirebaseUtils.uploadCarbonSource(source)
        
        FirebaseUtils.loadReferences(forSource: source, intoContext: self.backgroundContext) { (refs) in
            print("Downloaded \(refs.count) references for Carbon Source: \(source.name)")
            self.save()
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
        
        if (source.data?.count ?? 0) >= 1 {
            NotificationManager.shared.scheduleNotification(forSource: source)
        }
        
        FirebaseUtils.uploadCarbonDataPoint(point)
        
        // Query for the appropriate references
        if let sourceId = source.id {
            let request = CarbonReference.fetchAllRequest
            request.predicate = NSPredicate(format: "%K = %@", "source.id", sourceId)
            let references = try! self.backgroundContext.fetch(request)
            
            let month = Calendar.current.component(.month, from: date)
            for reference in references {
                let refMonth = Calendar.current.component(.month, from: reference.month as Date)
                if refMonth == month {
                    point.addToReferences(reference)
                }
            }
        }
        
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
    
    func getDefaultUnit(forSourceType sourceType: CarbonSource.SourceType) -> CarbonUnit? {
        guard let unit = try? CarbonUnit.defaultUnit(forSourceType: sourceType, inContext: self.backgroundContext) else {
            return nil
        }
        
        return unit
    }
}

enum CoreDataError: Error {
    case fetchError
    case duplicateError
}
