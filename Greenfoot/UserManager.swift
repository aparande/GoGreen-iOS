//
//  UserManager.swift
//  Greenfoot
//
//  Created by Anmol Parande on 10/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

class UserManager: LocationListener {
    let defaults: UserDefaults
    var user: User?
    
    static let shared: UserManager = UserManager()
    
    init(withDefaults defaults: UserDefaults) {
        self.defaults = defaults
        
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: DefaultsKeys.USER), let user = try? decoder.decode(User.self, from: data) {
            
            self.user = user
        } else {
            self.user = User(withId: UUID().uuidString)
            self.saveUser()
        }
    }
    
    private convenience init() {
        self.init(withDefaults: UserDefaults.standard)
    }
    
    func saveUser() {
        guard let user = self.user else { return }
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            defaults.set(encoded, forKey: DefaultsKeys.USER)
        }
        
        FirebaseUtils.updateUser(user)
    }
    
    func locationDidUpdate(to newLoc: Location?) {
        self.user?.locId = newLoc?.id
        self.saveUser()
    }
}
