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
import Firebase

class SettingsManager: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = SettingsManager()
    
    var shouldUseLocation:Bool
    var locality:Location?
    
    var canNotify:Bool
    var reminderTimings:[GreenDataType:ReminderSettings]?
    var scheduledReminders:[GreenDataType:String]
    
    let locationFailedNotification = NSNotification.Name.init(rawValue: "LocateFailed")
    let locationUpdatedNotification = NSNotification.Name.init(rawValue: "LocationUpdated")
    
    var profile: User
    
    private var loggingLocation = false
    
    override init() {
        let defaults = UserDefaults.standard
        
        if let user = User.fromDefaults(withKey: "Profile") {
            profile = user
        } else if let prof = defaults.object(forKey: "Profile") as? [String:Any] {
            profile = User(fromDict: prof)
        } else {
            
            if let uuid = defaults.string(forKey: "ProfId") {
                profile = User(withId: uuid)
            } else {
                profile = User(withId: UUID().uuidString)
                profile.saveToDefaults(forKey: "Profile")
            }
        }
        
        print(profile.id)
        
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

        if let locale_data = Location.fromDefaults(withKey: "Setting_Locale") {
            locality = locale_data
        } else {
            if let locale = GreenfootModal.sharedInstance.locality {
                self.locality = locale
                self.locality?.saveToDefaults(forKey: "Setting_Locale")
                self.shouldUseLocation = true
            }
        }
        
        
        FirebaseUtils.updateUser(profile)
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
        
        if loggingLocation {
            return
        }
        
        loggingLocation = true
        
        FirebaseUtils.uploadLocation(placemark) { (location) in
            if let locId = location.id, locId != self.locality?.id {
                #warning("Should prompt user that we detected a location change")
                print("Detected a Location Change")
                self.locality = location
                self.profile.locId = self.locality?.id
                
                GreenfootModal.sharedInstance.logEnergyPoints()
                
                location.saveToDefaults(forKey: "LocalityData")
                location.saveToDefaults(forKey: "Setting_Locale")
                
                FirebaseUtils.updateUser(self.profile)
                NotificationCenter.default.post(name: self.locationUpdatedNotification, object: self)
            }
            
            GreenfootModal.sharedInstance.data[GreenDataType.electric]!.fetchEGrid()
            GreenfootModal.sharedInstance.data[GreenDataType.electric]!.fetchConsumption()
        }
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
    
    func pruneNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (pendingRequests) in
            var pending:[GreenDataType] = []
            for request in pendingRequests {
                let reqId = request.identifier
                for dataType in GreenDataType.allValues {
                    if let id = self.scheduledReminders[dataType] {
                        pending.append(dataType)
                        if reqId != id {
                            self.scheduledReminders[dataType] = reqId //For some reason, if the notification in scheduled reminders has a different id, just update it
                        }
                    } else if reqId.range(of: dataType.rawValue) != nil {
                        //If the pending notification for some reason is not in scheduled reminders at all
                        self.scheduledReminders[dataType] = reqId
                        pending.append(dataType)
                    }
                }
            }
            
            //If there is no notification for a datatype, then make sure there is nothing about it in scheduled reminders
            for dataType in GreenDataType.allValues {
                if !pending.contains(dataType) {
                    print("Removing notification for \(dataType)")
                    self.scheduledReminders.removeValue(forKey: dataType) //We don't have to delete it from notification center because it's not there in the first place
                }
            }
        })
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
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let _ = email.index(of: "@") else {
            return completion(false, "Invalid Email Address")
        }
        
        if email == "" {
            return completion(false, "Please enter your email address")
        }
        
        if password == "" {
            return completion(false, "Please enter your password")
        }
        
        FirebaseUtils.loginUser(withEmail: email, andPassword: password, doOnSuccess: { (userId) in
            if self.profile.id != userId {
                FirebaseUtils.migrateUserData(fromId: self.profile.id!)
                self.profile.id = userId
            }
            
            self.profile.email = email
            
            let names = Auth.auth().currentUser!.displayName!.components(separatedBy: " ")
            self.profile.firstName = names[0]
            self.profile.lastName = names[1]
            
            self.profile.isLoggedIn = true
            self.profile.locId = self.locality?.id
            
            self.profile.saveToDefaults(forKey: "Profile")
            FirebaseUtils.updateUser(self.profile)
            
            #warning("This stuff basically redownloaded the location and overwrites the current user's location. Not even necessary?")
            /*
            if let downloadedLocation = data["location"] as? NSDictionary {
                if let _ = self.locality {
                    
                } else {
                    self.locality = nil
                }
                
                if downloadedLocation.object(forKey: "city") as? String != "null" {
                    self.locality = Location(fromDict: downloadedLocation.dictionaryWithValues(forKeys: ["Id", "City", "State", "Country", "ISOCode", "Zip"]))
                    self.shouldUseLocation = true
                }
                
                self.locality?.saveToDefaults(forKey: "Setting_Locale")
                
                if self.shouldUseLocation {
                    GreenfootModal.sharedInstance.locality = self.locality
                    #warning("Why the heck do I save this twice")
                    self.locality?.saveToDefaults(forKey: "LocalityData")
                }
                
                GreenfootModal.sharedInstance.data[GreenDataType.electric]!.fetchEGrid()
            }
            
            for (_, data) in GreenfootModal.sharedInstance.data {
                data.reachConsensus()
            }
            
            completion(true, nil) */
        }) { (errorMessage) in
            completion(false, errorMessage)
        }
    }
    
    func signup(email: String, password: String, retypedPassword: String, firstname: String, lastname: String, completion: @escaping (Bool, String?) -> Void) {
        if password == "" || email == "" || retypedPassword == "" || firstname == "" || lastname == "" {
            return completion(false, "Please fill out all fields")
        }
        
        if password != retypedPassword {
            return completion(false, "Passwords do not match")
        }
        
        if email == "" {
            return completion(false, "Please enter your email address")
        }
        
        if password.count < 8 {
            return completion(false, "Your password must be at least 8 characters")
        }
        
        guard let _ = email.index(of: "@") else {
            return completion(false, "Invalid Email Address")
        }
        
        FirebaseUtils.signUpUserWith(named: "\(firstname) \(lastname)", withEmail: email, andPassword: password, doOnSuccess: { (userId) in
            FirebaseUtils.migrateUserData(fromId: self.profile.id!)
            
            self.profile.id = userId
            self.profile.email = email
            self.profile.firstName = firstname
            self.profile.lastName = lastname
            self.profile.isLoggedIn = true
            self.profile.locId = self.locality?.id
        
            self.profile.saveToDefaults(forKey: "Profile")
            FirebaseUtils.updateUser(self.profile)
            
            completion(true, nil)
            
        }) { (errorMessage) in
            return completion(false, errorMessage)
        }
    }
    
    //Location data should be retrived from the Greenfoot modal if location settings are enabled.
    //If they are not enabled and the user is logged in, then use the location which is stored in settings
    //To make sure that the server and the device are not out of sync
    func getLocationData() -> Location? {
        guard let locality = GreenfootModal.sharedInstance.locality else {
            if self.profile.isLoggedIn {
                return self.locality
            }
            return nil
        }
        
        return locality
    }
}

enum Settings {
    case LocationAllowed, NotificationAllowed
}

enum ReminderSettings: String {
    case FirstOfMonth = "First of Each Month", OneMonth = "One Month from Last Point", None = "Never"
    
    static let allValues = [FirstOfMonth, OneMonth, None]
}
