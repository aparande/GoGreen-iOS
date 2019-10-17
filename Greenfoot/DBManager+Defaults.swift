//
//  DBManager+Defaults.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

extension DBManager {
    func loadDefaults() {
        print("Loading Defaults")
        
        DispatchQueue.global(qos: .utility).async {
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            FirebaseUtils.loadDefaultUnits(intoContext: self.backgroundContext) { (units) in
                for unit in units {
                    if unit.isDefault && unit.sourceType == .direct {
                        self.carbonUnit = unit
                    }
                }
                print("Loaded units")
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
            
            dispatchGroup.enter()
            FirebaseUtils.loadDefaultConversions(intoContext: self.backgroundContext) { (conversions) in
                print("Loaded conversions")
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
            
            DispatchQueue.main.async {
                print("Finished loading defaults")
                self.loadedFromFirebase = true
                self.defaults.set(true, forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS)
                self.save()
                
                NotificationCenter.default.post(name: DBManager.DEFAULTS_LOADED, object: nil)
            }
        }
    }
}
