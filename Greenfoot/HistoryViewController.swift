//
//  HistoryViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/26/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class HistoryViewController: UITableViewController {
    @IBOutlet weak var epHistoryChart: BarGraph!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationItem.backBarButtonItem?.tintColor = UIColor.white
        
        self.navigationItem.title = "Breakdown"
        self.navigationItem.titleLabel.textColor = UIColor.white
        self.navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 20)

        let cellNib = UINib(nibName: "MonthlyChangeCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "ChangeCell")
        
        var monthlyBreakdown:[Date:Double] = [:]
        
        for (_, data) in GreenfootModal.sharedInstance.data {
            for (month, value) in data.getEPData() {
                if let ep = monthlyBreakdown[month] {
                    monthlyBreakdown[month] = ep + Double(value)
                } else {
                    monthlyBreakdown[month] = Double(value)
                }
            }
        }
        
        epHistoryChart.loadData(monthlyBreakdown, labeled: "Energy Points")
        epHistoryChart.legend.enabled = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChangeCell", for: indexPath) as! MonthlyChangeTableViewCell

        var image:UIImage!
        var unit:String!
        var data:GreenData!
        switch indexPath.row {
        case 0:
            image = Icon.electric_white
            unit = "kWh"
            data = GreenfootModal.sharedInstance.data["Electric"]!
            break
        case 1:
            image = Icon.water_white
            unit = "gal"
            data = GreenfootModal.sharedInstance.data["Water"]!
            break
        case 2:
            image = Icon.smoke_white
            unit = "mi"
            data = GreenfootModal.sharedInstance.data["Emissions"]!
            break
        case 3:
            image = Icon.fire_white
            unit = "therm"
            data = GreenfootModal.sharedInstance.data["Gas"]!
            break
        default:
            image = Icon.logo_white
            unit = "Null"
            data = GreenfootModal.sharedInstance.data["Electric"]!
            break
        }
        
        let keys = data.getGraphData().keys.sorted(by: {
            (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedDescending
        })
        
        var info:[Date: Double] = [:]
        if keys.count == 2 {
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

}
