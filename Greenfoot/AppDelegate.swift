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
        
        
       // if UserDefaults.standard.bool(forKey: "CompletedTutorial") {
            for (_, data) in modal.data {
                data.reachConsensus()
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let tvc = GGTabController()
            
            let svc = storyboard.instantiateInitialViewController() as! NavigationController
            let summary = svc.viewControllers[0] as! SummaryViewController
            do {
                summary.aggregator = try SourceAggregator()
            } catch {
                #warning("This is a terrible error message")
                print("Encountered \(error.localizedDescription)")
                summary.errorOnPresent(titled: "Error", withMessage: "Something went wrong. Please try redownloading the app")
            }
            
            let logoButton = GGTabBarItem(icon: Icon.logo_white, title: "HOME", isRounded: true)
            logoButton.itemHeight = 80
            
            let travelButton = GGTabBarItem(icon: Icon.road_white, title: "TRAVEL", isRounded: false)
            let utilityButton = GGTabBarItem(icon: Icon.electric_white, title: "UTILITIES", isRounded: false)
            
            let travelData = try! SourceAggregator(fromCategories: [.travel])
            let utilityData = try! SourceAggregator(fromCategories: [.utility])
            
            let travelVc = NavigationController(rootViewController: UtilitiesTableViewController(withTitle: "Travel", aggregator: travelData))
            let utilityVc = NavigationController(rootViewController: UtilitiesTableViewController(withTitle: "Utilities", aggregator: utilityData))
            
            tvc.setTabBar(items: [travelButton, logoButton, utilityButton])
            tvc.viewControllers = [travelVc, svc, utilityVc]
            
            tvc.selectedIndex = 1
            
            window!.rootViewController = tvc
       /* } else {
        
            let pager = TutorialViewController()
            
            window!.rootViewController = pager
            
            //TEST THAT THIS WORKS
            SettingsManager.sharedInstance.shouldUseLocation = true
        }*/
        
        SettingsManager.sharedInstance.loadLocation()
        
        SettingsManager.sharedInstance.setNotificationCategories()
        SettingsManager.sharedInstance.pruneNotifications()
        
        window!.makeKeyAndVisible()
        
        style()
        
        return true
    }
    
    private func style() {
        let buttonAppearance = PopupDialogButton.appearance()
        buttonAppearance.titleFont = UIFont.button
        buttonAppearance.titleColor = Colors.green
        
        CancelButton.appearance().titleColor = .red
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.header
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attrs
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

