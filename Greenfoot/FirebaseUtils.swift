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
    static func uploadLocation(_ location: Location, completion: @escaping  ((Location) -> Void)) {
        var params = location.toJSON()
        
        Functions.functions().httpsCallable("uploadLocation").call(params) {
            (result, error) in
            #warning("Need to do error handling here")
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Firebase failed with code: \(code), message: \(message), details: \(details)")
                }
                return;
            }
            
            guard let functionData = result?.data as? [String:Any], let locData = functionData["data"] as? [String:Any] else {
                print("Couldn't decode data")
                return
            }
            
            let newLoc = Location(fromDict: locData)
            completion(newLoc)
        }
    }
    
    static func updateUser(_ user: User) {
        let store = Firestore.firestore()
        var userRef: DocumentReference!
        
        userRef = store.collection("Users").document(user.id!) //This is a good force unwrap because a User will always have an id
        userRef.setData(user.toJSON(), merge: true)
    }
    
    static func signUpUserWith(named name:String?, withEmail email: String, andPassword psd: String, doOnSuccess successFunc: @escaping (String) -> Void, elseOnFailure failureFunc: @escaping (String) -> Void) {
        Auth.auth().createUser(withEmail: email, password: psd) { (authRes, error) in
            if let err = error {
                print(err.localizedDescription)
                return failureFunc("Something went wrong. Please try again")
            }
            
            guard let authRes = authRes else { return failureFunc("Something went wrong. Please try again") }
            
            guard let name = name else { return successFunc(authRes.user.uid) }
            
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
        let functions = Functions.functions()
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

