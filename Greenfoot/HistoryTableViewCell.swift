//
//  HistoryTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/4/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class HistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var dateTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var amountLabel: MeasurementLabel!
    @IBOutlet weak var co2Label: MeasurementLabel!
    
    var point: CarbonDataPoint? {
        didSet {
            guard let dataPoint = point else { return }
            
            dateTitleLabel.text = (dataPoint.month as Date).toString(withFormat: "MMMM")
            dateLabel.text = (dataPoint.month as Date).toString(withFormat: "MM/yyyy")
            
            amountLabel.measurement = dataPoint
            amountLabel.prefix = "Amount: "
            
            co2Label.measurement = CarbonValue(rawValue: dataPoint.carbonValue)
            co2Label.prefix = "CO2: "
        }
    }
}
