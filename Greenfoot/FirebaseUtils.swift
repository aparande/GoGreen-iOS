//
//  FirebaseUtils.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/9/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

class FirebaseUtils {
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
    
    static func uploadLocation(_ placemark: CLPlacemark, completion: @escaping  ((Location) -> Void)) {
        #warning("It is not smart to be unwrapping these")
        let store = Firestore.firestore()
        let locRef = store.collection("Locations")
        
        var location = Location(fromPlacemark: placemark)
        var params = location.toJSON()
        
        guard let query = queryCollection(locRef, withParams: params) else { return }
        query.getDocuments { (snapshot, error) in
            if let error = error {
                print(error.localizedDescription)
                #warning("Need to do something if the id is nil")
                completion(location)
                return
            }
            
            guard let snapshot = snapshot else { return }
            if snapshot.isEmpty {
                let docRef = locRef.document()
                location.id = docRef.documentID
                params["id"] = location.id
                docRef.setData(params, merge: true)
                completion(location)
            } else {
                completion(Location(fromDict: snapshot.documents[0].data()))
            }
        }
    }
    
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
    
    static func updateUser(_ user: User) {
        let store = Firestore.firestore()
        var userRef: DocumentReference!
        
        userRef = store.collection("Users").document(user.id!) //This is a good force unwrap because a User will always have an id
        userRef.setData(user.toJSON(), merge: true)
    }
    
    static func signUpUserWith(named name:String, withEmail email: String, andPassword psd: String, doOnSuccess successFunc: @escaping (String) -> Void, elseOnFailure failureFunc: @escaping (String) -> Void) {
        Auth.auth().createUser(withEmail: email, password: psd) { (authRes, error) in
            if let err = error {
                print(err.localizedDescription)
                return failureFunc("Something went wrong. Please try again")
            }
            
            guard let authRes = authRes else { return failureFunc("Something went wrong. Please try again") }
            
            let changeRequest = authRes.user.createProfileChangeRequest()
            changeRequest.displayName = name
            
            changeRequest.commitChanges(completion: { (changeError) in
                if let err = error {
                    print(err.localizedDescription)
                    return failureFunc("Something went wrong. Please try again")
                }
                
                return successFunc(authRes.user.uid)
            })
        }
    }
    
    static func loginUser(withEmail email:String, andPassword psd: String, doOnSuccess successFunc: @escaping (String) -> Void, elseOnFailure failureFunc: @escaping (String) -> Void) {
        Auth.auth().signIn(withEmail: email, password: psd) { (authRes, error) in
            if let err = error {
                print(err.localizedDescription)
                return failureFunc("Email/Password Incorrect")
            }
            
            if let authRes = authRes {
                return successFunc(authRes.user.uid)
            } else {
                return failureFunc("Email/Password Incorrect")
            }
        }
    }
    
    static func migrateUserData(fromId id:String) {
        var functions = Functions.functions()
        functions.httpsCallable("migrateUserData").call(["oldId": id]) {
            (result, error) in
            #warning("Need to do error handling here")
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Firebase failed with code: \(code), message: \(message)")
                }
            }
        }
    }
    
    #warning("Does not support null types I think")
    static private func queryCollection(_ ref: CollectionReference, withParams params:[String : Any]) -> Query? {
        var query: Query?
        
        for (field, value) in params {
            guard let subquery = query else {
                query = ref.whereField(field, isEqualTo: value)
                continue
            }
            
            subquery.whereField(field, isEqualTo: value)
            query = subquery
        }
        
        return query
    }
}

