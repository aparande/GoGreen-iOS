//
//  FirebaseUtils-Firestore.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/18/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Firebase

extension FirebaseUtils {
    static func getEGridDataFor(zipCode zip: String, andState state: String, inCountry country:String = "US", completion: @escaping (Double?) -> Void) {
        let store = Firestore.firestore()
        
        store.collection("EGrid").document(country).collection("\(zip)-\(state)").document("default").getDocument { (snapshot, error) in
            if let err = error {
                print("Couldn't get EGrid data for \(zip)-\(state) because \(err.localizedDescription)")
                return completion(nil)
            }
            
            guard let data = snapshot?.data() else {
                print("Couldn't get EGrid data for \(zip)-\(state) because document dosen't exist")
                return completion(nil)
            }
            completion(Double(data["Factor"] as! String))
        }
    }
    
    static func getAverageFor(state: String, inCountry country:String = "US", type: GreenDataType, completion: @escaping (Double?) -> Void) {
        let store = Firestore.firestore()
        store.collection("Averages").document(type.rawValue).collection("\(state)-\(country)").document("default").getDocument {(snapshot, error) in
            
            if let err = error {
                print("Couldn't get Average data for \(state)-\(country) because \(err.localizedDescription)")
                return completion(nil)
            }
            
            guard let data = snapshot?.data() else {
                print("Couldn't get Average data for \(state)-\(country) because document dosen't exist")
                return completion(nil)
            }
            completion(Double(data["Value"] as! String))
        }
    }
}
