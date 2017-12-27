//
//  HistoryViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/26/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import Charts

class HistoryViewController: UITableViewController, ChartViewDelegate {
    @IBOutlet weak var epHistoryChart: BarGraph!
    
    var monthlyBreakdown:[Date:Double]!
    var totalCarbon: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleLabel.text = "Breakdown"
        self.navigationItem.titleLabel.textColor = UIColor.white
        self.navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 17)
    
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationItem.backButton.tintColor = UIColor.white

        let cellNib = UINib(nibName: "MonthlyChangeCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "ChangeCell")
        
        monthlyBreakdown = [:]
        
        for (_, data) in GreenfootModal.sharedInstance.data {
            for (month, value) in data.getEPData() {
                if let ep = monthlyBreakdown[month] {
                    monthlyBreakdown[month] = ep + Double(value)
                } else {
                    monthlyBreakdown[month] = Double(value)
                }
            }
            
            totalCarbon += data.totalCarbon
        }
        
        setFooterView()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "General Cell")
            
            let geoSans = UIFont(name: "Raleway", size: 17.0)
            cell.textLabel?.font = geoSans!
            cell.textLabel?.textColor = Colors.green
            
            let droidSans = UIFont(name: "GeosansLight", size: 20.0)
            cell.detailTextLabel?.font = droidSans
            cell.detailTextLabel?.textColor = Colors.green
            
            cell.textLabel?.text = "Carbon Dioxide Emitted: "
            cell.detailTextLabel?.text = "\(totalCarbon) lbs"
            
            cell.selectionStyle = .none
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChangeCell", for: indexPath) as! MonthlyChangeTableViewCell

        var image:UIImage!
        var unit:String!
        var data:GreenData!
        switch indexPath.row {
        case 1:
            image = Icon.electric_emblem
            unit = "kWh"
            data = GreenfootModal.sharedInstance.data[GreenDataType.electric]!
            break
        case 2:
            image = Icon.water_emblem
            unit = "gal"
            data = GreenfootModal.sharedInstance.data[GreenDataType.water]!
            break
        case 3:
            image = Icon.road_emblem
            unit = "mi"
            data = GreenfootModal.sharedInstance.data[GreenDataType.driving]!
            break
        case 4:
            image = Icon.fire_emblem
            unit = "therms"
            data = GreenfootModal.sharedInstance.data[GreenDataType.gas]!
            break
        default:
            image = Icon.leaf_emblem
            unit = "Null"
            data = GreenfootModal.sharedInstance.data[GreenDataType.electric]!
            break
        }
        
        let keys = data.getGraphData().keys.sorted(by: {
            (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedDescending
        })
        
        var info:[Date: Double] = [:]
        if keys.count >= 2 {
            let firstMonth = keys[0]
            let firstValue = data.getGraphData()[firstMonth]!
        
            let secondMonth = keys[1]
            let secondValue = data.getGraphData()[secondMonth]!
            info = [firstMonth:firstValue, secondMonth:secondValue]
        } else if keys.count == 1 {
            let month = keys[0]
            let value = data.getGraphData()[month]!
            info = [month:value]
        }
        
        
        cell.setInfo(icon: image, info: info, unit: unit)
        
        return cell
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let keys = monthlyBreakdown.keys.sorted(by: {
            (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedAscending
        })
        
        if Int(entry.x) >= keys.count {
            return
        }
        
        let date = keys[Int(entry.x)]
        let modal = GreenfootModal.sharedInstance
        var data:[String: Double] = [:]
        if let electric = modal.data[GreenDataType.electric]!.getEPData()[date] {
            data[GreenDataType.electric.rawValue] = Double(electric)
        }
        
        if let water = modal.data[GreenDataType.water]!.getEPData()[date] {
            data[GreenDataType.water.rawValue] = Double(water)
        }
        
        if let driving = modal.data[GreenDataType.driving]!.getEPData()[date] {
            data[GreenDataType.driving.rawValue] = Double(driving)
        }
        
        if let gas = modal.data[GreenDataType.gas]!.getEPData()[date] {
            data[GreenDataType.gas.rawValue] = Double(gas)
        }
        
        let dpvc = DataPointViewController(timestamp: Date.monthFormat(date: date), values: data)
        self.navigationController?.pushViewController(dpvc, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func setFooterView() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: 200))
        
        let graphWidth = self.tableView.frame.width-20
        
        let graph = BarGraph(frame: CGRect(x: 10, y: 10, width: graphWidth, height: graphWidth * 0.5))
        graph.loadData(monthlyBreakdown, labeled: "Energy Points")
        graph.legend.enabled = true
        graph.legend.textColor = UIColor.white
        graph.legend.font = UIFont.boldSystemFont(ofSize: 8)
        graph.delegate = self
        container.addSubview(graph)
        
        graph.highlightValues(nil)
        
        self.tableView.tableFooterView = container
    }

}
