//
//  SettingsManager.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/2/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class SettingsManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = SettingsManager()
    
    var shouldUseLocation = true
    var locality:[String:String]?
    
    var canNotify:Bool
    
    let locationFailedNotification = NSNotification.Name.init(rawValue: "LocateFailed")
    let locationUpdatedNotification = NSNotification.Name.init(rawValue: "LocationUpdated")
    
    override init() {
        self.canNotify = UserDefaults.standard.bool(forKey: "NotificationSetting")
        
        if let locale_data = UserDefaults.standard.dictionary(forKey: "Setting_Locale") as? [String:String] {
            locality = locale_data
        }
    }
    
    let locationManager = CLLocationManager()
    
    func loadLocation() {
        if shouldUseLocation {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        shouldUseLocation = false
        NotificationCenter.default.post(name: locationFailedNotification, object: nil)
        print("Error while updating location " + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: {
            (placemarks, error) in
            if error != nil {
                print("Reverse geocoder failed with error "+error!.localizedDescription)
                return
            }
            if placemarks?.count != 0 {
                let pm = placemarks![0] as CLPlacemark
                self.saveLocationInfo(placemark: pm)
            } else {
                print("Problem with the data received")
            }
        })
    }
    
    func saveLocationInfo(placemark: CLPlacemark) {
        locationManager.stopUpdatingLocation()
        
        guard let locale = GreenfootModal.sharedInstance.locality else {
            var localityData:[String:String] = [:]
            localityData["City"] = placemark.locality
            localityData["State"] = placemark.administrativeArea
            localityData["Country"] = placemark.country
            localityData["Zip"] = placemark.postalCode
            GreenfootModal.sharedInstance.locality = localityData
            self.locality = localityData
            print("Saved locale: \(localityData)")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            for (key, value) in GreenfootModal.sharedInstance.data {
                for (month, amount) in value.getGraphData() {
                    let date = formatter.string(from: month)
                    if !value.uploadedData.contains(date) {
                        value.addToServer(month: date, point: amount)
                    }
                }
                
                if key == .electric {
                    value.fetchEGrid()
                    value.fetchConsumption()
                }
            }
            
            GreenfootModal.sharedInstance.logEnergyPoints()
            
            UserDefaults.standard.set(localityData, forKey:"LocalityData")
            UserDefaults.standard.set(localityData, forKey:"Setting_Locale")
            
            NotificationCenter.default.post(name: locationUpdatedNotification, object: self)
            
            return
        }
        
        guard let _ = self.locality else {
            self.locality = locale
            UserDefaults.standard.set(locale, forKey:"Setting_Locale")
            return
        }

        GreenfootModal.sharedInstance.data[GreenDataType.electric]!.fetchConsumption()
    }
    
    func setNotificationCategories() {
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                     actions: [],
                                                     intentIdentifiers: [],
                                                     options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([generalCategory])
    }
    
    func requestNotificationPermissions(completion: ((Bool) -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: {
            (granted, error) in
            if (error != nil) {
                print(error.debugDescription)
            }
            
            self.canNotify = granted
            
            if granted {
                for (_, value) in GreenfootModal.sharedInstance.data {
                    value.timeToNotification = 30
                }
            }
            
            if let closure = completion {
                closure(granted)
            }
        })
    }
}
