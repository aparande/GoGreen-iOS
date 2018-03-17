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

class BarGraphFooter: UIView {
    @IBOutlet weak var barGraph: BarChartView!
}

class HistoryViewController: UITableViewController, ChartViewDelegate {
    var epHistoryChart: BarGraph!
    
    var monthlyBreakdown:[Date:Double]!
    var totalCarbon: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepNavigationBar(titled: "Breakdown")

        let cellNib = UINib(nibName: "MonthlyChangeCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "ChangeCell")
        
        monthlyBreakdown = [:]
        
        for (_, data) in GreenfootModal.sharedInstance.data {
            for point in data.getEPData() {
                if let ep = monthlyBreakdown[point.month] {
                    monthlyBreakdown[point.month] = ep + Double(point.value)
                } else {
                    monthlyBreakdown[point.month] = Double(point.value)
                }
            }
            
            totalCarbon += data.totalCarbon
        }
        
        if let footerView = UINib(nibName: "BarGraphFooter", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? BarGraphFooter {
            let footerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.frame.width, height: 0.5 * self.tableView.frame.width))
            footerView.frame = footerFrame
            self.tableView.tableFooterView = footerView
            
            epHistoryChart = footerView.barGraph as! BarGraph
            
            epHistoryChart.loadData(monthlyBreakdown, labeled: "Energy Points")
            epHistoryChart.legend.enabled = true
            epHistoryChart.legend.textColor = UIColor.white
            epHistoryChart.legend.font = UIFont.boldSystemFont(ofSize: 8)
            epHistoryChart.delegate = self
        }
        
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

        var info:[Date: Double] = [:]
        let graphData = data.getGraphData()
        if graphData.count >= 2 {
            let firstMonth = graphData[0].month
            let firstValue = graphData[0].value
            
            let secondMonth = graphData[0].month
            let secondValue = graphData[0].value
            info = [firstMonth:firstValue, secondMonth:secondValue]
        } else if graphData.count == 1 {
            let month = graphData[0].month
            let value = graphData[0].value
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
        if let electric = modal.data[GreenDataType.electric]!.findPointForDate(date, ofType: .energy) {
            data[GreenDataType.electric.rawValue] = Double(electric.value)
        }
        
        if let water = modal.data[GreenDataType.water]!.findPointForDate(date, ofType: .energy) {
            data[GreenDataType.water.rawValue] = Double(water.value)
        }
        
        if let driving = modal.data[GreenDataType.driving]!.findPointForDate(date, ofType: .energy) {
            data[GreenDataType.driving.rawValue] = Double(driving.value)
        }
        
        if let gas = modal.data[GreenDataType.gas]!.findPointForDate(date, ofType: .energy) {
            data[GreenDataType.gas.rawValue] = Double(gas.value)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        epHistoryChart.highlightValues(nil)
    }
}
