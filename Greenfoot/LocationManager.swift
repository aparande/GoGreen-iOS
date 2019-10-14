//
//  LocationManager.swift
//  Greenfoot
//
//  Created by Anmol Parande on 10/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationListener {
    func locationDidUpdate(to newLoc: Location?)
}

class LocationManager:NSObject, CLLocationManagerDelegate {
    private let defaults: UserDefaults
    private let locationManager: CLLocationManager
    private let shouldUseLocation: Bool
    
    static let shared = LocationManager(withDefaults: UserDefaults.standard)
    
    var location: Location? {
        didSet {
            self.listener?.locationDidUpdate(to: self.location)
        }
    }
    
    var listener: LocationListener?
    
    init(withDefaults defaults: UserDefaults) {
        self.defaults = defaults
        
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: DefaultsKeys.LOCATION), let location = try? decoder.decode(Location.self, from: data) {
            self.location = location
        }
        
        self.shouldUseLocation = true
        
        self.locationManager = CLLocationManager()
        
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func pollLocation() {
        if self.shouldUseLocation {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            print("Did not load location because User has turned it off")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!) { (placemarks, error) in
            if let err = error {
                print("Reverse geocoder failed with error: " + err.localizedDescription)
                return
            }
            
            if placemarks?.count != 0 {
                let pm = placemarks![0] as CLPlacemark
                self.saveLocation(pm)
                self.stopPollingLocation()
            }
        }
    }
    
    func stopPollingLocation() {
        self.locationManager.stopUpdatingLocation()
    }
    
    private func saveLocation(_ placemark: CLPlacemark) {
        self.location = Location(fromPlacemark: placemark)
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self.location) {
            defaults.set(encoded, forKey: DefaultsKeys.LOCATION)
        }
        
        FirebaseUtils.uploadLocation(self.location!) { (location) in
            if let locId = location.id, locId != self.location?.id {
                self.location = location
            }
        }
    }
}
