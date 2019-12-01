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

public extension CodingUserInfoKey {
    // Helper property to retrieve the context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
    static let userId = CodingUserInfoKey(rawValue: "userId")
    static let source = CodingUserInfoKey(rawValue: "source")
}

extension FirebaseObject {
    func toJSON(withInfo userInfo:[CodingUserInfoKey:Any] = [:]) -> [String:Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.userInfo = userInfo
        
        #warning("Force unwrapping encoding")
        let data = try! encoder.encode(self)
        let obj = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
        
        return obj
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
        self.postalCode = dict["postalCode"] as! String
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

