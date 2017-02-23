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
    
    func summary() {
        let summaryVC = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        let nvc = NavigationController(rootViewController: summaryVC)
        navigationDrawerController?.transition(to: nvc)
        navigationDrawerController?.closeLeftView()
    }
    func electric() {
        let electricVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Electric")
        let nvc = NavigationController(rootViewController: electricVC)
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
        default:
            electric()
            break
        }
    }
}
