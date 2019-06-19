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
    
    static func getDataForType(_ type: String, completion: @escaping ([GreenDataPoint]) -> Void) {
        let store = Firestore.firestore()
        let userId = SettingsManager.sharedInstance.profile.id!
        
        store.collection("Energy Data").document(type).collection(userId).getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get \(type) data because \(err.localizedDescription)")
                return completion([])
            }
            
            guard let snapshot = snapshot else {
                print("Couldn't get \(type) data because snapshot doesn't exist")
                return completion([])
            }
            
            var data:[GreenDataPoint] = []
            
            do {
                for doc in snapshot.documents {
                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: .prettyPrinted)
                    let point = try JSONDecoder().decode(GreenDataPoint.self, from: jsonData)
                    data.append(point)
                }
            } catch {
                print("Couldn't get \(type) data because \(error.localizedDescription)")
                return completion([])
            }
            
            return completion(data)
        }
    }
    
    static func getCars(completion: @escaping ([String:Int]) -> Void) {
        let store = Firestore.firestore()
        let userId = SettingsManager.sharedInstance.profile.id!
        
        store.collection("Energy Data").document(GreenDataType.car.rawValue).collection(userId).getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get cars data because \(err.localizedDescription)")
                return completion([:])
            }
            
            guard let snapshot = snapshot else {
                print("Couldn't get cars because snapshot doesn't exist")
                return completion([:])
            }
            
            var data:[String:Int] = [:]
            
            for doc in snapshot.documents {
                let docData = doc.data()
                
                guard let carName = docData["name"] as? String else { continue }
                guard let mileage = docData["mileage"] as? Int else { continue }
                
                data[carName] = mileage
            }
            
            return completion(data)
        }
    }
    
    static func getDataForCar(_ car: String, completion: @escaping ([GreenDataPoint]) -> Void) {
        let store = Firestore.firestore()
        let userId = SettingsManager.sharedInstance.profile.id!
        store.collection("Energy Data").document(GreenDataType.car.rawValue).collection(userId).document(car).collection("Readings").getDocuments { (snapshot, error) in
            if let err = error {
                print("Couldn't get data for car:\(car) because \(err.localizedDescription)")
                return completion([])
            }
            
            guard let snapshot = snapshot else {
                print("Couldn't get get data for car:\(car) because snapshot doesn't exist")
                return completion([])
            }
            
            var data:[GreenDataPoint] = []
            
            do {
                for doc in snapshot.documents {
                    let jsonData = try JSONSerialization.data(withJSONObject: doc.data(), options: .prettyPrinted)
                    let point = try JSONDecoder().decode(GreenDataPoint.self, from: jsonData)
                    data.append(point)
                }
            } catch {
                print("Couldn't get data for car:\(car) because \(error.localizedDescription)")
                return completion([])
            }
            
            return completion(data)
        }
    }
}
