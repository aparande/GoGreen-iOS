//
//  CoreDataProtocols.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataRecord: NSFetchRequestResult, Decodable {
    associatedtype Record: NSFetchRequestResult, Decodable
    
    static var fetchAllRequest: NSFetchRequest<Record> { get }
    static func all(inContext context: NSManagedObjectContext) throws -> [Record]
    static func with(id: String, fromContext context: NSManagedObjectContext) throws -> Record?
    static func createIfUnique(inContext context: NSManagedObjectContext, withData data: [String:Any]) -> Record?
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
    
    static func createIfUnique(inContext context: NSManagedObjectContext, withData data: [String:Any]) -> Record? {
        guard let id = data["id"] as? String else { return nil }
        
        if let record = try? self.with(id: id, fromContext: context) {
            return record
        }
        
        let decoder = JSONDecoder()
        decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = context
        guard let json = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) else { return nil }
        guard let newObj = try? decoder.decode(Record.self, from: json) else { return nil }
        return newObj
    }
}

protocol CoreJsonObject {
    init?(inContext context: NSManagedObjectContext, fromJson json:[String:Any])
}
