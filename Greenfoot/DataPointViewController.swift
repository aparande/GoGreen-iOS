//
//  DataPointViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/28/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Charts

class DataPointViewController: UITableViewController {
    var values: [String:Double]
    var date: String
    var unit: String
    var data: GreenData
    
    init(unit: String, timestamp: String, values: [String:Double], data:GreenData) {
        date = timestamp
        self.values = values
        self.unit = unit
        self.data = data
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        
        self.navigationItem.title = date
        self.navigationItem.titleLabel.textColor = UIColor.white
        self.navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 17)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ValueCell")
        
        cell.textLabel?.font = UIFont(name: "DroidSans", size: 17.0)
        cell.textLabel?.textColor = Colors.green
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = unit
            cell.detailTextLabel?.text = "\(values["Usage"]!)"
            break
        case 1:
            cell.textLabel?.text = "Energy Points"
            cell.detailTextLabel?.text = "\(values["EP"]!)"
            break
        case 2:
            cell.textLabel?.text = "Pounds of Carbon"
            if let value = values["Carbon"] {
                cell.detailTextLabel?.text = "\(value)"
            } else {
                cell.detailTextLabel?.text = "NA"
            }
            break
        default:
            cell.textLabel?.text = "null"
            cell.detailTextLabel?.text = "null"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.width, height: 200))
        
        let graph = HorizontalBarChartView(frame: CGRect(x: 10, y: 10, width: self.tableView.width-20, height: 180))
        
        graph.isUserInteractionEnabled = false
        
        var data:[String:Double] = ["You":values["Usage"]!, "U.S":self.data.baseline]
        if let stateConsumption = self.data.stateConsumption {
            data[(GreenfootModal.sharedInstance.locality?["State"])!] = stateConsumption
        }
        
        graph.loadData(data, labeled: "Comparison")
        
        container.addSubview(graph)
        return container
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
}
