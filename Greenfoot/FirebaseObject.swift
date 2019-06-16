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
    
    func toJSON() -> [String:Any]
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
}

struct Location: FirebaseObject {
    var id: String?
    var city: String
    var state: String
    var country: String
    var isoCode: String
    var zip: String
    
    init(fromPlacemark placemark: CLPlacemark) {
        self.city = placemark.locality!
        self.state = placemark.administrativeArea!
        self.country = placemark.country!
        self.isoCode = placemark.isoCountryCode!
        self.zip = placemark.postalCode!
    }
    
    init(fromDict dict: [String:Any]) {
        self.id = dict["id"] as! String
        self.city = dict["city"] as! String
        self.state = dict["state"] as! String
        self.country = dict["country"] as! String
        self.isoCode = dict["isoCode"] as! String
        self.zip = dict["zip"] as! String
    }
        
    func saveToDefaults(forKey key:String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    static func fromDefaults(withKey key: String) -> Location? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(Location.self, from: data)
    }
}

