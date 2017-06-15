//
//  CoreDataHelper.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/14/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataHelper {
    static let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    //Fetches graph data from the modal and loads it into the GreenData
    static func fetch(data: GreenData) {
        if let _ = appDelegate {
            let managedContext = appDelegate!.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:data.dataName)
            
            do {
                let managedObjects = try managedContext.fetch(fetchRequest)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yy"
                for managedObj in managedObjects {
                    let date = managedObj.value(forKeyPath: "month") as! Date
                    let amount = managedObj.value(forKeyPath: "amount") as! Double
                    //Unwrap the optional pls
                    let uploaded = managedObj.value(forKeyPath: "uploaded") as! Bool
                    
                    if uploaded {
                        data.uploadedData.append(formatter.string(from: date))
                    }
                    
                    data.addDataPoint(month: date, y: amount, save: false)
                }
                print("Loaded Data For \(data.dataName)")
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    //Saves a data point to GreenData
    static func save(data: GreenData, month: Date, amount: Double) {
        if let _ = appDelegate {
            let managedContext = appDelegate!.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: data.dataName, in: managedContext)!
            
            let point = NSManagedObject(entity: entity, insertInto: managedContext)
            
            point.setValue(month, forKeyPath: "month")
            point.setValue(amount, forKeyPath: "amount")
            point.setValue(false, forKey: "uploaded")
            
            do {
                try managedContext.save()
                //You should likely do the adding here
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    static func update(data: GreenData, month:Date, updatedValue: Double, uploaded: Bool) {
        if let _ = appDelegate {
            let predicate = NSPredicate(format: "month == %@", argumentArray: [month])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: data.dataName)
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate!.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                fetchedEntities.first?.setValue(updatedValue, forKeyPath: "amount")
                fetchedEntities.first?.setValue(uploaded, forKeyPath: "uploaded")
            } catch let error as NSError {
                print("Could not update. \(error), \(error.userInfo)")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    static func delete(data: GreenData, month: Date) {
        if let _ = appDelegate {
            let predicate = NSPredicate(format: "month == %@", argumentArray: [month])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: data.dataName)
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate!.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                if let selected = fetchedEntities.first {
                    managedContext.delete(selected)
                }
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
}
