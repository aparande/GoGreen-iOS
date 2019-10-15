//
//  FirebaseUtils+Defaults.swift
//  Greenfoot
//
//  Created by Anmol Parande on 10/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Firebase
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
            
            guard let snapshot = snapshot else { print("Booga"); return completion([]) }
            let decoder = JSONDecoder()
            decoder.userInfo[CodingUserInfoKey.managedObjectContext!] = context
            
            var units = [CarbonUnit]()
            for document in snapshot.documents {
                guard let json = try? JSONSerialization.data(withJSONObject: document.data(), options: .prettyPrinted) else { print("Poop"); continue }
                
                guard let newUnit = try? decoder.decode(CarbonUnit.self, from: json) else { print("Great"); continue }
                
                units.append(newUnit)
            }
            return completion(units)
        }
    }
}
