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
    var unit: String?
    var data: GreenData?
    var isData: Bool
    
    init(timestamp:String, values: [String: Double]) {
        date = timestamp
        self.values = values
        isData = false
        
        super.init(style: .plain)
    }
    
    init(unit: String, timestamp: String, values: [String:Double], data:GreenData) {
        date = timestamp
        self.values = values
        self.unit = unit
        self.data = data
        isData = true
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.backButton.tintColor = UIColor.white
        
        self.navigationItem.title = date
        self.navigationItem.titleLabel.textColor = UIColor.white
        self.navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 17)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isData) ? 3 : values.keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = (isData) ? setDataCells(indexPath: indexPath) : setUnitCells(indexPath: indexPath)
        
        cell.textLabel?.font = UIFont(name: "DroidSans", size: 17.0)
        cell.textLabel?.textColor = Colors.green
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.width, height: 200))
        
        if isData {
            let graph = HorizontalBarChartView(frame: CGRect(x: 10, y: 10, width: self.tableView.width-20, height: 180))
            
            graph.isUserInteractionEnabled = false
            
            var data:[String:Double] = ["You":values["Usage"]!, "U.S":self.data!.baseline]
            if let stateConsumption = self.data!.stateConsumption {
                data[(GreenfootModal.sharedInstance.locality?["State"])!] = stateConsumption
            }
            
            graph.loadData(data, labeled: unit!)
            
            container.addSubview(graph)
        } else {
            let graph = BarGraph(frame: CGRect(x: 10, y: 10, width: self.tableView.width-20, height: 180))
            graph.isUserInteractionEnabled = false
            let data:[String:Double] = values
            
            graph.loadData(data)
            container.addSubview(graph)
        }
        
        return container
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
    
    private func setDataCells(indexPath: IndexPath) -> UITableViewCell{
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ValueCell")
        
        var detailValue:Double?
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = unit
            detailValue =  values["Usage"]!
            break
        case 1:
            cell.textLabel?.text = "Energy Points"
            detailValue = values["EP"]!
            break
        case 2:
            cell.textLabel?.text = "Pounds of Carbon"
            detailValue = values["Carbon"]
            break
        default:
            cell.textLabel?.text = "null"
            cell.detailTextLabel?.text = "null"
        }
        
        if let value = detailValue {
            cell.detailTextLabel?.text = "\(Int(value))"
        } else {
            cell.detailTextLabel?.text = "NA"
        }
        
        return cell
    }
    
    private func setUnitCells(indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "ValueCell")
        
        
        switch Array(values.keys)[indexPath.row] {
        case "Electric":
            cell.textLabel?.text = "Electricity Consumption"
            cell.detailTextLabel?.text = "\(Int(values["Electric"]!)) EP"
            break
        case "Water":
            cell.textLabel?.text = "Water Consumption"
            cell.detailTextLabel?.text = "\(Int(values["Water"]!)) EP"
            break
        case "Driving":
            cell.textLabel?.text = "Driving"
            cell.detailTextLabel?.text = "\(Int(values["Driving"]!)) EP"
            break
        case "Gas":
            cell.textLabel?.text = "Natural Gas"
            cell.detailTextLabel?.text = "\(Int(values["Gas"]!)) EP"
            break
        default:
            cell.textLabel?.text = "null"
            cell.detailTextLabel?.text = "null"
        }
        
        return cell
    }
}
