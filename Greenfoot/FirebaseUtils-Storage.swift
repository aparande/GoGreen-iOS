//
//  FirebaseUtils-Storage.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/18/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension FirebaseUtils {
    #warning("Can the following methods be condensed into one?")
    static func logData(_ point: GreenDataPoint) {
        let store = Firestore.firestore()
        
        guard let userId = SettingsManager.sharedInstance.profile.id else { return }
        
        let pointsRef = store.collection("Energy Data").document(point.dataType).collection(userId)
        let docRef = pointsRef.document()
        
        point.id = docRef.documentID
        
        let payload = point.toJSON()
        docRef.setData(payload)
    }
    
    static func editData(_ point: GreenDataPoint) {
        guard let id = point.id else { return } //Because if the id doesn't exist, this point isn't uploaded
        
        let store = Firestore.firestore()
        
        guard let userId = SettingsManager.sharedInstance.profile.id else { return }
        
        let pointRef = store.collection("Energy Data").document(point.dataType).collection(userId).document(id)
        
        pointRef.updateData(point.toJSON())
    }
    
    static func createCar(named name: String, withMileage mileage: Int) {
        let userId = SettingsManager.sharedInstance.profile.id!
        
        let store = Firestore.firestore()
        let ref = store.collection("Energy Data").document("Car").collection(userId).document(name)
        
        let payload:[String:Any] = ["name":name, "mileage": mileage]
        ref.setData(payload)
    }
    
    static func addOdometerReading(_ point: GreenDataPoint, toCar car: String) {
        let userId = SettingsManager.sharedInstance.profile.id!
        
        let store = Firestore.firestore()
        let ref = store.collection("Energy Data").document("Car").collection(userId).document(car).collection("Readings")
        
        let docRef = ref.document()
        
        point.id = docRef.documentID
        
        let payload = point.toJSON()
        docRef.setData(payload)
    }
}
