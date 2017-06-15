//
//  AppDelegate.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import CoreLocation
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: Screen.bounds)
        
        //You wont use this, but initialize it so the tutorial view controller isn't laggy
        let _ = GreenfootModal.sharedInstance
        
        if UserDefaults.standard.bool(forKey: "CompletedTutorial") {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
      
            let svc = storyboard.instantiateViewController(withIdentifier: "Summary")
            let nvc = NavigationController(rootViewController: svc)
        
            let dvc = storyboard.instantiateViewController(withIdentifier: "Drawer")
            let ndvc = NavigationDrawerController(rootViewController: nvc, leftViewController: dvc, rightViewController: nil)
            window!.rootViewController = ndvc
        } else {
        
            let pager = TutorialViewController()
            
            window!.rootViewController = pager
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        window!.makeKeyAndVisible()
        
        return true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
        
        guard let _ = GreenfootModal.sharedInstance.locality else {
            var localityData:[String:String] = [:]
            localityData["City"] = placemark.locality
            localityData["State"] = placemark.administrativeArea
            localityData["Country"] = placemark.country
            GreenfootModal.sharedInstance.locality = localityData
            print("Saved locale")
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            for (_, value) in GreenfootModal.sharedInstance.data {
                for (month, amount) in value.getGraphData() {
                    let date = formatter.string(from: month)
                    if !value.uploadedData.contains(date) {
                        value.addToServer(month: date, point: amount)
                    }
                }
            }
            return
        }
    }
    
    // CORE-DATA
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "greenfoot")
        container.loadPersistentStores(completionHandler: {
            (storeDescription, error) in
            
            if let error = error as NSError? {
                print(error)
            }
        })
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print(nserror)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let defaults = UserDefaults.standard
        let modal = GreenfootModal.sharedInstance
        for (key, value) in modal.data {
            let data = value.data
            let bonusAttrs = value.bonusDict
            
            defaults.set(data, forKey: key+":data")
            defaults.set(bonusAttrs, forKey: key+":bonus")
            
            if let emissions = value as? EmissionsData {
                defaults.set(emissions.carMileage, forKey: "MilesData")
            }

        }
        
        if let locality = modal.locality {
            defaults.set(locality, forKey:"LocalityData")
        }
        
        defaults.synchronize()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

