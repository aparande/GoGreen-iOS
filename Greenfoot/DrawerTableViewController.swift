//
//  DrawerTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/2/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class DrawerTableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    private func summary() {
        let summaryVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        let nvc = NavigationController(rootViewController: summaryVC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    private func electric() {
        let electricVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        
        let electricData = GreenfootModal.sharedInstance.data["Electric"]!
        
        electricVC.setDataType(data:electricData)
        let nvc = NavigationController(rootViewController: electricVC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    
    private func water() {
        let waterVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        
        let waterData = GreenfootModal.sharedInstance.data["Water"]!
        
        waterVC.setDataType(data:waterData)
        let nvc = NavigationController(rootViewController: waterVC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    
    private func emissions() {
        let co2VC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        let co2Data = GreenfootModal.sharedInstance.data["Emissions"]!
        
        co2VC.setDataType(data: co2Data)
        
        let nvc = NavigationController(rootViewController: co2VC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    
    private func gas() {
        let gasVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        let gasData = GreenfootModal.sharedInstance.data["Gas"]!
        
        gasVC.setDataType(data: gasData)
        
        let nvc = NavigationController(rootViewController: gasVC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.row) {
        case 0:
            summary()
            break
        case 1:
            electric()
            break
        case 2:
            water()
        case 3:
            emissions()
            break
        case 4:
            gas()
            break
        default:
            summary()
            break
        }
    }
}
