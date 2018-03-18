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
                let managedObjects = try managedContext.fetch(fetchRequest)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yy"
                for managedObj in managedObjects {
                    let date = managedObj.value(forKeyPath: "month") as! Date
                    let amount = managedObj.value(forKeyPath: "amount") as! Double
                    let dataPoint = GreenDataPoint(month: date, value: amount, dataType: data.dataName)
                    if let lastUpdated = managedObj.value(forKeyPath: "lastUpdated") as? Date {
                        dataPoint.lastUpdated = lastUpdated
                    }
                    
                    data.addDataPoint(point: dataPoint, save: false)
                }
                
                data.sortData()
                
                print("Loaded Data For \(data.dataName)")
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    //Saves a data point to GreenData
    static func save(dataPoint: GreenDataPoint) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let entity = NSEntityDescription.entity(forEntityName: "DataPoint", in: context)!
                
                let point = NSManagedObject(entity: entity, insertInto: context)
                
                point.setValue(dataPoint.month, forKeyPath: "month")
                point.setValue(dataPoint.value, forKeyPath: "amount")
                point.setValue(dataPoint.dataType, forKey: "dataType")
                //Make sure to update the point before saving it then
                point.setValue(dataPoint.lastUpdated, forKey: "lastUpdated")
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    static func update(point: GreenDataPoint) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "dataType == %@ AND month == %@", argumentArray: [point.dataType, point.month])
                
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DataPoint")
                fetchRequest.predicate = predicate
                
                do {
                    let fetchedEntities = try context.fetch(fetchRequest)
                    fetchedEntities.first?.setValue(point.value, forKeyPath: "amount")
                    fetchedEntities.first?.setValue(point.lastUpdated, forKeyPath: "lastUpdated")
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
    
    static func delete(point: GreenDataPoint) {
        if let _ = appDelegate {
            let container = appDelegate!.persistentContainer
            container.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "dataType == %@ AND month == %@", argumentArray: [point.dataType, point.month])
                
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
