//
//  Summary-TableView.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/30/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

extension SummaryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.textColor = .black
        label.font = UIFont.header
        
        if section == 0 {
            label.text = "Monthly Emissions"
        } else {
            label.text = "View Data"
        }
        
        headerView.addSubview(label)
        
        label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        headerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10).isActive = true
        label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10).isActive = true
        headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10).isActive = true
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        }
        
        let selectedDataType = GreenDataType.recordedValues[indexPath.row]
        let data = GreenfootModal.sharedInstance.data[selectedDataType]
        self.performSegue(withIdentifier: "toGraphView", sender: data)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 200
        case 1:
            return 100
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return GreenDataType.recordedValues.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func setupTableContainer() {
        tableContainerView.backgroundColor = UIColor.clear
        tableContainerView.layer.shadowColor = UIColor.darkGray.cgColor
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        tableContainerView.layer.shadowOpacity = 1.0
        tableContainerView.layer.shadowRadius = 10
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.estimatedSectionHeaderHeight = 40
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor.white
        tableView.layer.cornerRadius = 20
        tableView.layer.masksToBounds = true
        tableView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
    }
}