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
            let predicate = NSPredicate(format: "dataType == %@", argumentArray: [data.dataName])
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
            fetchRequest.predicate = predicate
            
            do {
                var unuploaded: [Date: Double] = [:]
                let managedObjects = try managedContext.fetch(fetchRequest)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yy"
                for managedObj in managedObjects {
                    let date = managedObj.value(forKeyPath: "month") as! Date
                    let amount = managedObj.value(forKeyPath: "amount") as! Double
                    let uploaded = managedObj.value(forKeyPath: "uploaded") as! Bool
                    print("\(data.dataName):\(date):\(amount):\(uploaded)")
                    
                    if uploaded {
                        data.uploadedData.append(formatter.string(from: date))
                    } else {
                        unuploaded[date] = amount
                    }
                    
                    data.addDataPoint(month: date, y: amount, save: false)
                }
                print("Loaded Data For \(data.dataName)")
                
                DispatchQueue.global(qos: .background).async {
                    for (key, value) in unuploaded {
                        data.addToServer(month: Date.monthFormat(date: key), point: value)
                    }
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    //Saves a data point to GreenData
    static func save(data: GreenData, month: Date, amount: Double) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: context)!
                
                let point = NSManagedObject(entity: entity, insertInto: context)
                
                point.setValue(month, forKeyPath: "month")
                point.setValue(amount, forKeyPath: "amount")
                point.setValue(false, forKey: "uploaded")
                point.setValue(data.dataName, forKey: "dataType")
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    static func update(data: GreenData, month:Date, updatedValue: Double, uploaded: Bool) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "dataType == %@ AND month == %@", argumentArray: [data.dataName, month])
                
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
                fetchRequest.predicate = predicate
                
                do {
                    let fetchedEntities = try context.fetch(fetchRequest)
                    fetchedEntities.first?.setValue(updatedValue, forKeyPath: "amount")
                    fetchedEntities.first?.setValue(uploaded, forKeyPath: "uploaded")
                } catch let error as NSError {
                    print("Could not update. \(error), \(error.userInfo)")
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    static func delete(data: GreenData, month: Date) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "dataType == %@ AND month == %@", argumentArray: [data.dataName, month])
                
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
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
}
