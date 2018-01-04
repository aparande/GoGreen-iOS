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
        
        //You wont use this, but initialize it so the tutorial view controller isn't laggy
        
        let _ = GreenfootModal.sharedInstance
        
        if UserDefaults.standard.bool(forKey: "CompletedTutorial") {
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
        }
        
        SettingsManager.sharedInstance.loadLocation()
        
        SettingsManager.sharedInstance.setNotificationCategories()
        
        window!.makeKeyAndVisible()
        
        return true
    }
    
    private func getGraphController(forDataType type:GreenDataType, andTag tag:Int) -> NavigationController {
        let graphVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        graphVC.setDataType(data:GreenfootModal.sharedInstance.data[type]!)
        
        var icon: UIImage!
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
        }
        icon = icon.withRenderingMode(.alwaysTemplate).resize(toWidth: 30)?.resize(toHeight: 30)
        graphVC.tabBarItem = UITabBarItem(title: type.rawValue, image: icon, tag: tag)
        
        return NavigationController(rootViewController: graphVC)
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

            defaults.set(data, forKey: key.rawValue+":data")
            defaults.set(bonusAttrs, forKey: key.rawValue+":bonus")
            
            if SettingsManager.sharedInstance.canNotify {
                defaults.set(value.timeToNotification, forKey: key.rawValue+":notificationTime")
            }
        }
        
        if modal.rankings.keys.count == 4 {
            defaults.set(modal.rankings, forKey:"Rankings")
        }
        
        defaults.set(SettingsManager.sharedInstance.canNotify, forKey:"NotificationSetting")
        
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

