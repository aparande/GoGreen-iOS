//
//  FirebaseUtils+Defaults.swift
//  Greenfoot
//
//  Created by Anmol Parande on 10/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import FirebaseFirestore
import CoreData

extension FirebaseUtils {
    static func loadDefaultUnits(intoContext context: NSManagedObjectContext, completion: @escaping ([CarbonUnit]) -> Void) {
        let store = Firestore.firestore()
        
        let locRef = store.collection("CarbonUnits")
        let query = locRef.whereField("isPreloaded", isEqualTo: true)
        
        query.getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get default carbon units because \(err.localizedDescription)")
                return completion([])
            }
            
            guard let snapshot = snapshot else { return completion([]) }
            var units = [CarbonUnit]()
            
            for document in snapshot.documents {
                guard let newUnit = CarbonUnit.createIfUnique(inContext: context, withData: document.data()) else { continue }
                
                units.append(newUnit)
            }
            return completion(units)
        }
    }
    
    static func loadDefaultConversions(intoContext context: NSManagedObjectContext, completion: @escaping ([Conversion]) -> Void) {
        let store = Firestore.firestore()
        
        let locRef = store.collection("CarbonConversions")
        let query = locRef.whereField("isPreloaded", isEqualTo: true)
        
        query.getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get default carbon conversions because \(err.localizedDescription)")
                return completion([])
            }
            
            
            guard let snapshot = snapshot else { return completion([])}
            
            var conversions = [Conversion]()
            for document in snapshot.documents {
                guard let newConv = Conversion.createIfUnique(inContext: context, withData: document.data()) else {continue}
                conversions.append(newConv)
            }
            
            return completion(conversions)
        }
    }
}
