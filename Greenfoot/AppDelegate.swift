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
        
        LocationManager.shared.listener = UserManager.shared
        LocationManager.shared.pollLocation()
        
                    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let tvc = GGTabController()
        
        let logoButton = GGTabBarItem(icon: Icon.logo_white, title: "HOME", isRounded: true)
        logoButton.itemHeight = 80
                            
        let svc = storyboard.instantiateInitialViewController() as! NavigationController
        let summary = svc.viewControllers[0] as! SummaryViewController
        summary.aggregator = SourceAggregator()
    
        let travelData = try! SourceAggregator(fromCategories: [.travel])
        let utilityData = try! SourceAggregator(fromCategories: [.utility])
        
        let travelVc = NavigationController(rootViewController: UtilitiesTableViewController(withTitle: "Travel", forCategory: .travel, aggregator: travelData))
        let utilityVc = NavigationController(rootViewController: UtilitiesTableViewController(withTitle: "Utilities", forCategory: .utility, aggregator: utilityData))
    
        let travelButton = GGTabBarItem(icon: Icon.electric_white, title: "Projects", isRounded: false)
        let utilityButton = GGTabBarItem(icon: Icon.logo_white, title: "Footprint", isRounded: false)
        
        tvc.setTabBar(items: [travelButton, utilityButton])
        tvc.selectedIndex = 1
        
        let mtvc = SlidingTabsController(viewControllers: [travelVc, svc, utilityVc], withTitles: ["Travel", "Summary", "Utilities"], selectedIndex: 1)
        
        let dummyVC = UIViewController()
        
        tvc.viewControllers = [mtvc, dummyVC]
        
        let presenterVc = StatusBarController(rootViewController: tvc)
        presenterVc.statusBar.backgroundColor = Colors.green
        presenterVc.displayStyle = .partial
        
        window!.rootViewController = presenterVc
        
        window!.makeKeyAndVisible()
        
        style()
        
        return true
    }
    
    private func style() {
        let buttonAppearance = PopupDialogButton.appearance()
        buttonAppearance.titleFont = UIFont.button
        buttonAppearance.titleColor = Colors.green
        
        CancelButton.appearance().titleColor = .red
        
        FlatButton.appearance().tintColor = .white
        
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.header
        ]
        
        UINavigationBar.appearance().titleTextAttributes = attrs
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //let defaults = UserDefaults.standard
                
        /*
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
        
        defaults.synchronize() */
    }
}

