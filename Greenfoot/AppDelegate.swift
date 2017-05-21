//
//  AppDelegate.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: Screen.bounds)
        
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
        
        window!.makeKeyAndVisible()
        return true
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
            var serializableGraphData:[String: Double] = [:]
            
            for (key, value) in value.getGraphData() {
                serializableGraphData[Date.longDateToString(date: key)] = value
            }
            
            defaults.set(data, forKey: key+":data")
            defaults.set(bonusAttrs, forKey: key+":bonus")
            defaults.set(serializableGraphData, forKey: key+":graph")

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

