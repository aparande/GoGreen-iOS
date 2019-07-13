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
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var co2Label: UILabel!
    
    var point: GreenDataPoint? {
        didSet {
            guard let dataPoint = point else { return }
            let amount = dataPoint.value
            let co2 = "DUMMY"
            
            dateTitleLabel.text = dataPoint.month.toString(withFormat: "MMMM")
            dateLabel.text = dataPoint.month.toString(withFormat: "MM/yyyy")
            amountLabel.text = "Amount: \(amount)"
            co2Label.text = "CO2: \(co2)"
        }
    }
}
