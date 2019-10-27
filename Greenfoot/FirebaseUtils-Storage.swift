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
    static func uploadCarbonSource(_ source: CarbonSource) {
        guard let userId = UserManager.shared.user.id else {
            return
        }
        
        let store = Firestore.firestore()
        let ref = store.collection("CarbonSources").document()
        source.id = ref.documentID
        
        let payload = source.toJSON(withInfo: [CodingUserInfoKey.userId!:userId])
        ref.setData(payload)
    }
    
    static func uploadCarbonDataPoint(_ point: CarbonDataPoint) {
        guard let userId = UserManager.shared.user.id else {
            return
        }
        
        let store = Firestore.firestore()
        let ref = store.collection("CarbonDataPoints").document()
        point.id = ref.documentID
        
        let payload = point.toJSON(withInfo: [CodingUserInfoKey.userId!: userId])
        ref.setData(payload)
    }
}
