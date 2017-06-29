//
//  MonthlyChangeTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/26/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class MonthlyChangeTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var firstMonthValueLabel: UILabel!
    @IBOutlet weak var secondMonthValueLabel: UILabel!
    @IBOutlet weak var changeLabel: UILabel!
    
    @IBOutlet weak var firstMonthLabel: UILabel!
    @IBOutlet weak var secondMonthLabel: UILabel!
    
    func setInfo(icon: UIImage, info:[Date: Double], unit: String) {
        iconImageView.image = icon
        
        let keys = info.keys.sorted(by: { (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedAscending
        })
        
        if keys.count == 1 {
            firstMonthLabel.text = "No Data"
            firstMonthValueLabel.text = "NA"
            
            secondMonthLabel.text = "\(unit) on \(Date.monthFormat(date: keys[0]))"
            secondMonthValueLabel.text = "\(Int(info[keys[0]]!))"
            
            changeLabel.text = "\(Int(info[keys[0]]!))"
            changeLabel.textColor = Colors.green
        } else if keys.count == 2 {
            firstMonthLabel.text = "\(unit) on \(Date.monthFormat(date: keys[0]))"
            firstMonthValueLabel.text = "\(Int(info[keys[0]]!))"
            
            secondMonthLabel.text = "\(unit) on \(Date.monthFormat(date: keys[1]))"
            secondMonthValueLabel.text = "\(Int(info[keys[1]]!))"
            
            changeLabel.text = "\(Int(abs(info[keys[1]]! - info[keys[0]]!)))"
            
            changeLabel.textColor = (info[keys[1]]! - info[keys[0]]! <= 0) ? Colors.red : Colors.green
        } else {
            firstMonthLabel.text = "No Data"
            firstMonthValueLabel.text = "NA"
            
            secondMonthLabel.text = "No Data"
            secondMonthValueLabel.text = "NA"
            
            changeLabel.text = "NA"
            changeLabel.textColor = Colors.green
        }
    }
}
