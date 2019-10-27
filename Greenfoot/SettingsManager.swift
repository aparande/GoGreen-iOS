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
    /*
    static let sharedInstance = SettingsManager()
        
    var canNotify:Bool
    var reminderTimings:[String:ReminderSettings]
    var scheduledReminders:[String:String]
        
    var profile: User
    
    private var shouldUpdateUser = false
    
    override init() {
        
        let defaults = UserDefaults.standard
                
        self.canNotify = defaults.bool(forKey: "NotificationSetting")
        
        self.scheduledReminders = [:]
        self.reminderTimings = [:]
        
        var email:String?
        var password: String?
        
        self.profile = User(withId: UUID().uuidString)
        
        if let user = User.fromDefaults(withKey: "Profile") {
            self.profile = user
        } else if let prof = defaults.object(forKey: "Profile") as? [String:Any] {
            self.profile = User(fromDict: prof)
            
            email = prof["email"] as? String
            password = prof["password"] as? String
        } else {
            
            if let uuid = defaults.string(forKey: "ProfId") {
                self.profile = User(withId: uuid)
            } else {
                self.profile = User(withId: UUID().uuidString)
                //self.profile.saveToDefaults(forKey: "Profile")
            }
        }
        
        super.init()
        
        if let reminderQueue = defaults.object(forKey: "ScheduledReminders") as? [String:String] {
            self.scheduledReminders = reminderQueue
        }
        
        if let reminders = defaults.object(forKey: "ReminderSettings") as? [String:String] {
            for (key, value) in reminders {
                self.reminderTimings![key] = ReminderSettings(rawValue: value)!
            }
        }
        
        //This means the user was signed in on the old version of the app, so we need to create their user in Firebase
        if let email = email, let pass = password {
            FirebaseUtils.signUpUserWith(named: nil, withEmail: email, andPassword: pass, doOnSuccess: { (userId) in
                FirebaseUtils.migrateUserData(fromId: self.profile.id!)
                self.profile.id =  userId
                self.profile.isLoggedIn = true
                print("User was signed in on old device. New Id is \(self.profile.id!)")
                FirebaseUtils.updateUser(self.profile)
            }) { (message) in
                #warning("Should do something to notify the user/try again")
                return
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
                GreenfootModal.sharedInstance.locality = location
                
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
            
            /(
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
            
            //If the account was created on the old version, then display name won't exist
            if let names = Auth.auth().currentUser?.displayName?.components(separatedBy: " ") {
                self.profile.firstName = names[0]
                self.profile.lastName = names[1]
            }
            
            self.profile.isLoggedIn = true
            
            #warning("This will overwrite the location stored on the server. Is this right?")
            self.profile.locId = self.locality?.id
            
            //self.profile.saveToDefaults(forKey: "Profile")
            FirebaseUtils.updateUser(self.profile)
            
            completion(true, nil)
        }) { (errorMessage) in
            print("Couldn't find account on Firebase. Trying on old server")
            /*
            self.loginWithServer(email: email, password: password, completion: { (success, message) in
                completion(success, message)
            }) */
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
        
            //self.profile.saveToDefaults(forKey: "Profile")
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
    
    private func loginWithServer(email: String, password: String, completion: @escaping (Bool, String?) -> Void ) {
        let parameters:[String: Any] = ["email": email, "password":password]
        let id = APIRequestType.login.rawValue
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "login", withParameters: parameters, andSuccessFunction: {
            (data) in
            print(data)
            
            guard let oldId = data["UserId"] as? String else { return completion(false, "Please check your network connection or try again later")}
            
            FirebaseUtils.signUpUserWith(named: nil, withEmail: email, andPassword: password, doOnSuccess: { (userId) in
                FirebaseUtils.migrateUserData(fromId: self.profile.id!)
                
                self.profile.id = userId
                self.profile.email = email
                self.profile.isLoggedIn = true
                
                FirebaseUtils.updateUser(self.profile)
                
                for dataObj in GreenfootModal.sharedInstance.data.values {
                    dataObj.consensusWithOldServer(usingOldId: oldId)
                }
                
                completion(true, nil)
            }, elseOnFailure: { (error) in
                print(error)
                completion(false, "Please check your network connection or try again later")
            })
        }, andFailureFunction: {
            (err) in
            guard let errorType = err["Error"] as? APIError else {
                return completion(false, nil)
            }
            
            if errorType == .serverFailure {
                completion(false, "Incorrect Username/Password Combination")
            } else {
                completion(false, "Please check your network connection or try again later")
            }
        })
    } */
}

enum Settings {
    case LocationAllowed, NotificationAllowed
}

enum ReminderSettings: String {
    case FirstOfMonth = "First of Each Month", OneMonth = "One Month from Last Point", None = "Never"
    
    static let allValues = [FirstOfMonth, OneMonth, None]
}
