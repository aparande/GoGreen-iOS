//
//  CoreDataProtocols.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData

protocol CoreDataRecord {
    associatedtype Record: NSFetchRequestResult
    
    static var fetchAllRequest: NSFetchRequest<Record> { get }
    static func all(inContext context: NSManagedObjectContext) throws -> [Record]
}

protocol CoreJsonObject {
    init?(inContext context: NSManagedObjectContext, fromJson json:[String:Any])
}
