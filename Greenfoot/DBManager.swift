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
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    init(container: NSPersistentContainer) {
        self.persistentContainer = container
    }
    
    convenience init() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Can't get shared app delegate")
        }
        
        self.init(container: appDelegate.persistentContainer)
    }
    
    private func save() {
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
        source.sourceCategory = category.rawValue
        source.sourceType = type.rawValue
        
        self.save()
    }
}
