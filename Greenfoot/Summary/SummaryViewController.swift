//
//  ViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import Charts
import UserNotifications

class SummaryViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let graphNib = UINib(nibName: "BarGraphCell", bundle: nil)
        tableView.register(graphNib, forCellReuseIdentifier: "GraphCell")
        
        let logNib = UINib(nibName: "LogCell", bundle: nil)
        tableView.register(logNib, forCellReuseIdentifier: "LogCell")
        
        tableView.separatorStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GraphCell") as! BarGraphTableViewCell
            cell.graph.loadDataFrom(array: GreenfootModal.sharedInstance.data[.electric]!.getGraphData(), labeled: "")
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogCell") as! LogTableViewCell
            
            let type = GreenDataType.recordedValues[indexPath.row]
            cell.title = type.rawValue
            cell.icon = GreenDataType.getImage(for: type)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 200
        case 1:
            return 100
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return GreenDataType.recordedValues.count
        default:
            return 0
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Monthly Emissions"
        } else {
            return "View Data"
        }
    }
}

extension UIViewController {
    func prepToolbar() {
        let logo = UIImageView(image: Icon.logo_white)
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.barTintColor = Colors.green
    }
    
    func prepSegmentedToolbar(segmentAction: Selector) {
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let segmentedView = UISegmentedControl(items: ["Usage", "Energy Points", "Carbon"])
        segmentedView.selectedSegmentIndex = 0
        segmentedView.layer.cornerRadius = 5.0
        segmentedView.tintColor = UIColor.white
        
        navigationItem.centerViews = [segmentedView]
        
        segmentedView.addTarget(self, action: segmentAction, for: .valueChanged)
    }
    
    func prepNavigationBar(titled title:String?) {
        if let text = title {
            navigationItem.titleLabel.text = text
            navigationItem.titleLabel.textColor = UIColor.white
            navigationItem.titleLabel.font = UIFont.header
        }
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        navigationItem.backButton.tintColor = UIColor.white
    }
}
