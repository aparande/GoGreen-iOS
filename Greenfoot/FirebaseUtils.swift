//
//  FirebaseUtils.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/9/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Firebase

class FirebaseUtils {
    static func getEGridDataFor(zipCode zip: String, andState state: String, completion: @escaping (Double?) -> Void) {
        let store = Firestore.firestore()
        
        store.collection("EGrid").document("\(zip)-\(state)").getDocument { (snapshot, error) in
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
}

