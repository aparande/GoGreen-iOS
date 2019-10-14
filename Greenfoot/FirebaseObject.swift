//
//  FirebaseObject.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/15/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreLocation

protocol FirebaseObject: Codable {
    var id: String? {get set}
}

extension FirebaseObject {
    func toJSON() -> [String:Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        #warning("Force unwrapping encoding")
        let data = try! encoder.encode(self)
        let obj = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
        
        return obj
    }
    
    func saveToDefaults(forKey key:String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

struct Location: FirebaseObject {
    var id: String?
    var locality: String // City
    var administrativeArea: String // State
    var country: String
    var isoCode: String
    var postalCode: String
    
    init(fromPlacemark placemark: CLPlacemark) {
        self.locality = placemark.locality!
        self.administrativeArea = placemark.administrativeArea!
        self.country = placemark.country!
        self.isoCode = placemark.isoCountryCode!
        self.postalCode = placemark.postalCode!
    }
    
    init(fromDict dict: [String:Any]) {
        self.id = dict["id"] as? String
        self.locality = dict["locality"] as! String
        self.administrativeArea = dict["administrativeArea"] as! String
        self.country = dict["country"] as! String
        self.isoCode = dict["isoCode"] as! String
        self.postalCode = dict["zip"] as! String
    }
    
    mutating func reassignId(to id: String) {
        self.id = id
    }
    
    static func fromDefaults(withKey key: String) -> Location? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(Location.self, from: data)
    }
}

struct User: FirebaseObject {
    var id: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var locId: String?
    var isLoggedIn: Bool = false
    
    //A method to ensure backwards compatability
    init(fromDict dict: [String:Any]) {
        self.id = dict["profId"] as? String
        self.email = dict["email"] as? String
        self.firstName = dict["firstName"] as? String
        self.lastName = dict["lastName"] as? String
        self.locId = dict["locId"] as? String
    }
    
    init(withId id:String) {
        self.id = id
    }
}

