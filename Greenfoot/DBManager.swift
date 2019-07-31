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
    
    init(container: NSPersistentContainer, defaults: UserDefaults) {
        self.persistentContainer = container
        self.defaults = defaults
        
        if !self.defaults.bool(forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS) {
            self.loadDefaults()
            self.defaults.set(true, forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS)
        }
    }
    
    convenience init() {
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
    
    func createCarbonSource(name:String, category: CarbonSource.SourceCategory, type: CarbonSource.SourceType) {
        let source = CarbonSource(context: backgroundContext)
        source.name = name
        source.sourceCategory = category
        source.sourceType = type
        
        self.save()
    }
}
