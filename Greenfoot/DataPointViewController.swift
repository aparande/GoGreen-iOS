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
        
        prepNavigationBar(titled: date)
        
        setFooter()
        tableView.cellLayoutMarginsFollowReadableWidth = false
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let footerView = self.tableView.tableFooterView {
            if footerView.frame.height != 0.5 * self.tableView.frame.width {
                let footerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.frame.width, height: 0.5 * self.tableView.frame.width))
                footerView.frame = footerFrame
                self.tableView.tableFooterView = footerView
            }
        }
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
        cell.selectionStyle = .none
        
        return cell
    }
    
    func setFooter() {
        if isData {
            if let footerView = UINib(nibName: "BarGraphFooter", bundle: nil).instantiate(withOwner: nil, options: nil)[1] as? BarGraphFooter {
                let footerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.frame.width, height: 0.5 * self.tableView.frame.width))
                footerView.frame = footerFrame
                self.tableView.tableFooterView = footerView
                
                footerView.barGraph.isUserInteractionEnabled = false
                
                var data:[String:Double] = ["You":values["Usage"]!, "U.S":self.data!.baseline]
                if let stateConsumption = self.data!.stateConsumption {
                    data[(GreenfootModal.sharedInstance.locality?["State"])!] = stateConsumption
                }
                
                if let graph = footerView.barGraph as? HorizontalBarChartView {
                    graph.loadData(data, labeled: unit!)
                }
            }
        } else {
            if let footerView = UINib(nibName: "BarGraphFooter", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? BarGraphFooter {
                let footerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.frame.width, height: 0.5 * self.tableView.frame.width))
                footerView.frame = footerFrame
                self.tableView.tableFooterView = footerView
                
                footerView.barGraph.isUserInteractionEnabled = false
                let data:[String:Double] = values
                
                if let graph = footerView.barGraph as? BarGraph {
                    graph.loadData(data)
                }
            }
        }
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
        
        let key = Array(values.keys)[indexPath.row]
        cell.detailTextLabel?.text = "\(Int(values[key]!)) EP"
        
        switch key {
        case GreenDataType.electric.rawValue:
            cell.textLabel?.text = "Electricity Consumption"
            break
        case GreenDataType.water.rawValue:
            cell.textLabel?.text = "Water Consumption"
            break
        case GreenDataType.driving.rawValue:
            cell.textLabel?.text = "Driving"
            break
        case GreenDataType.gas.rawValue:
            cell.textLabel?.text = "Natural Gas"
            break
        default:
            cell.textLabel?.text = "null"
            cell.detailTextLabel?.text = "null"
        }
        
        return cell
    }
}
