//
//  AppDelegate.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import CoreData
import PopupDialog
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // CORE-DATA
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "greenfoot")
        container.loadPersistentStores(completionHandler: {
            (storeDescription, error) in
            
            if let error = error as NSError? {
                print(error)
            }
        })
        
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return container
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: Screen.bounds)
        
        FirebaseApp.configure()
        
        let modal = GreenfootModal.sharedInstance
        
        if UserDefaults.standard.bool(forKey: "CompletedTutorial") {
            for (_, data) in modal.data {
                data.reachConsensus()
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
      
            let tvc = UITabBarController()
            
            let svc = storyboard.instantiateViewController(withIdentifier: "Summary")
            let sNVC = NavigationController(rootViewController: svc)
            let sumBarImage = UIImage(named: "Chart_Green")?.withRenderingMode(.alwaysTemplate).resize(toWidth: 30)?.resize(toHeight: 30)
            svc.tabBarItem = UITabBarItem(title: "Summary", image: sumBarImage, tag: 1)
            
            let electricVc = getGraphController(forDataType: GreenDataType.electric, andTag: 2)
            let waterVc = getGraphController(forDataType: GreenDataType.water, andTag: 3)
            let drivingVc = getGraphController(forDataType: GreenDataType.driving, andTag: 4)
            let gasVc = getGraphController(forDataType: GreenDataType.gas, andTag: 5)
            
            tvc.viewControllers = [sNVC, electricVc, waterVc, drivingVc, gasVc]
            
            tvc.tabBar.tintColor = Colors.green
        
            window!.rootViewController = tvc
        } else {
        
            let pager = TutorialViewController()
            
            window!.rootViewController = pager
            
            //TEST THAT THIS WORKS
            SettingsManager.sharedInstance.shouldUseLocation = true
        }
        
        SettingsManager.sharedInstance.loadLocation()
        
        SettingsManager.sharedInstance.setNotificationCategories()
        SettingsManager.sharedInstance.pruneNotifications()
        
        window!.makeKeyAndVisible()
        
        style()
        
        return true
    }
    
    private func style() {
        let buttonAppearance = PopupDialogButton.appearance()
        buttonAppearance.titleFont = UIFont(name: "DroidSans", size: 15)
        buttonAppearance.titleColor = Colors.green
        
        CancelButton.appearance().titleColor = .red
    }
    
    private func getGraphController(forDataType type:GreenDataType, andTag tag:Int) -> NavigationController {
        let graphVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        graphVC.setDataType(data:GreenfootModal.sharedInstance.data[type]!)
        
        var icon: UIImage!
        
        #warning("This switch statement is repeated")
        switch type {
        case .electric:
            icon = Icon.electric_white
            break
        case .water:
            icon = Icon.water_white
            break
        case .driving:
            icon = Icon.road_white
            break
        case .gas:
            icon = Icon.fire_white
            break
        default:
            icon = Icon.logo_white
            break
        }
        icon = icon.withRenderingMode(.alwaysTemplate).resize(toWidth: 30)?.resize(toHeight: 30)
        graphVC.tabBarItem = UITabBarItem(title: type.rawValue, image: icon, tag: tag)
        
        return NavigationController(rootViewController: graphVC)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        let defaults = UserDefaults.standard
        let modal = GreenfootModal.sharedInstance
        for (key, value) in modal.data {
            let data = value.data
            let bonusAttrs = value.bonusDict
            
            //Must encode as JSON because otherwise swift can't store structs in UserDefaults.
            let encodedData = try? JSONEncoder().encode(data)
            let encodedBonus = try? JSONEncoder().encode(bonusAttrs)

            defaults.set(encodedData, forKey: key.rawValue+":data")
            defaults.set(encodedBonus, forKey: key.rawValue+":bonus")
        }
        
        if modal.rankings.keys.count == 4 {
            defaults.set(modal.rankings, forKey:"Rankings")
        }
        
        
        if let reminderSettings = SettingsManager.sharedInstance.reminderTimings {
            var reminder: [String:String] = [:]
            for (key, value) in reminderSettings {
                reminder[key.rawValue] = value.rawValue
            }
            defaults.set(reminder, forKey: "ReminderSettings")
        }
        
        defaults.set(SettingsManager.sharedInstance.canNotify, forKey:"NotificationSetting")
        defaults.set(SettingsManager.sharedInstance.shouldUseLocation, forKey:"LocationSetting")
        
        var scheduledReminders: [String:String] = [:]
        for (key, value) in SettingsManager.sharedInstance.scheduledReminders {
            scheduledReminders[key.rawValue] = value
        }
        defaults.set(scheduledReminders, forKey: "ScheduledReminders")
        
        defaults.synchronize()
    }
}

