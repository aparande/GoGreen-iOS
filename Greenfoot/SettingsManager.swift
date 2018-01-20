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
    
    var shouldUseLocation:Bool
    var locality:[String:String]?
    
    var canNotify:Bool
    var reminderTimings:[GreenDataType:ReminderSettings]?
    var scheduledReminders:[GreenDataType:String]
    
    let locationFailedNotification = NSNotification.Name.init(rawValue: "LocateFailed")
    let locationUpdatedNotification = NSNotification.Name.init(rawValue: "LocationUpdated")
    
    var profile:[String:Any]
    
    override init() {
        let defaults = UserDefaults.standard
        
        if let prof = defaults.object(forKey: "Profile") as? [String:Any] {
            profile = prof
        } else {
            profile = ["linked":false]
            
            if let uuid = defaults.string(forKey: "ProfId") {
                profile["profId"] = uuid
            } else {
                let uuid = UUID().uuidString
                profile["profId"] = uuid
                defaults.set(profile, forKey: "Profile")
            }
        }
        
        scheduledReminders = [:]
        if let reminderQueue = defaults.object(forKey: "ScheduledReminders") as? [String:String] {
            for (key, value) in reminderQueue{
                self.scheduledReminders[GreenDataType(rawValue: key)!] = value
            }
        }
        
        self.canNotify = defaults.bool(forKey: "NotificationSetting")
        self.shouldUseLocation = UserDefaults.standard.bool(forKey: "LocationSetting")
        
        if let reminders = defaults.object(forKey: "ReminderSettings") as? [String:String] {
            self.reminderTimings = [:]
            for (key, value) in reminders {
                self.reminderTimings![GreenDataType(rawValue: key)!] = ReminderSettings(rawValue: value)!
            }
        }
        
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
            
            for (key, value) in GreenfootModal.sharedInstance.data {
                value.reachConsensus()
                
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
                guard let _ = self.reminderTimings else {
                    self.reminderTimings = [:]
                    for key in GreenDataType.allValues {
                        self.reminderTimings![key] = .FirstOfMonth
                    }
                    return
                }
            }
            
            if let closure = completion {
                closure(granted)
            }
        })
    }
    
    func cancelNotificationforDataType(_ dataType: GreenDataType) {
        if let id = scheduledReminders[dataType] {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            scheduledReminders.removeValue(forKey: dataType)
        }
    }
    
    func cancelAllNotifications() {
        var scheduledIds:[String] = []
        for dataType in GreenDataType.allValues {
            if let id = scheduledReminders[dataType] {
                scheduledIds.append(id)
                scheduledReminders.removeValue(forKey: dataType)
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: scheduledIds)
    }
    
    func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        let parameters:[String:Any] = ["email":email, "password":password]
        
        let id = APIRequestType.login.rawValue
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "login", withParameters: parameters, andSuccessFunction: {
            (data) in
            print(data)
            
            self.profile["profId"] = data["UserId"] as? String
            self.profile["email"] = email
            self.profile["password"] = password
            self.profile["linked"] = true
            for (_, data) in GreenfootModal.sharedInstance.data {
                data.reachConsensus()
            }
            
            completion(true)
        }, andFailureFunction: {
            (err) in
            print(err["Message"]!)
            completion(false)
        })
    }
}

enum Settings {
    case LocationAllowed, NotificationAllowed
}

enum ReminderSettings: String {
    case FirstOfMonth = "First of Each Month", OneMonth = "One Month from Last Point", None = "Never"
    
    static let allValues = [FirstOfMonth, OneMonth, None]
}
