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
    
    static func loadReferences(forSource source:CarbonSource, intoContext context: NSManagedObjectContext, completion: @escaping ([CarbonReference]) -> Void) {
        guard let locId =  UserManager.shared.user.locId else {
            completion([])
            return
        }
        
        let ref = Firestore.firestore().collection("CarbonReferences")
        let query = ref.whereField("locId", isEqualTo: locId).whereField("sourceType", isEqualTo: source.sourceType.rawValue)
        query.getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get carbon references because \(err.localizedDescription)")
                return completion([])
            }
            
            guard let snapshot = snapshot else {return completion([])}
            
            var references = [CarbonReference]()
            for document in snapshot.documents {
                var data = document.data()
                data["source"] = source
                guard let newRef = CarbonReference.createIfUnique(inContext: context, withData: data) else { continue }
                references.append(newRef)
            }
            
            return completion(references)
        }
    }
}
