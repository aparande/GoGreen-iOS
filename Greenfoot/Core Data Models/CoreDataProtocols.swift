//
//  CoreDataProtocols.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataRecord: NSFetchRequestResult {
    associatedtype Record: NSFetchRequestResult 
    
    static var fetchAllRequest: NSFetchRequest<Record> { get }
    static func all(inContext context: NSManagedObjectContext) throws -> [Record]
    static func with(id: String, fromContext context: NSManagedObjectContext) throws -> Record?
}

extension CoreDataRecord {
    static var fetchAllRequest: NSFetchRequest<Record> {
        get {
            let request = NSFetchRequest<Record>(entityName: String(describing: Self.self))
            return request
        }
    }
    
    static func all(inContext context: NSManagedObjectContext) throws -> [Record] {
        return try context.fetch(fetchAllRequest)
    }
    
    static func with(id: String, fromContext context: NSManagedObjectContext) throws -> Record? {
        let fetchRequest = fetchAllRequest
        fetchRequest.predicate = NSPredicate(format: "%K = %@", "id", id)
        return try context.fetch(fetchRequest).first
    }
}

protocol CoreJsonObject {
    init?(inContext context: NSManagedObjectContext, fromJson json:[String:Any])
}
