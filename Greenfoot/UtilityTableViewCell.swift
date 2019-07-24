//
//  UtilityTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class UtilityTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var leftTitleLabel: UILabel!
    @IBOutlet weak var rightTitleLabel: UILabel!
    @IBOutlet weak var totalCO2Label: UILabel!
    @IBOutlet weak var lastMonthLabel: UILabel!
    @IBOutlet weak var lastRecordedLabel: UILabel!
    @IBOutlet weak var primaryActionButton: RoundedIconButton!
    @IBOutlet weak var leftActionButton: RoundedIconButton!
    @IBOutlet weak var rightActionButton: RoundedIconButton!
    @IBOutlet weak var roundedView: UIView!
    
    var title: String = "" {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    var totalCo2: Double = 0 {
        didSet {
            self.totalCO2Label.text = "\(totalCo2)"
        }
    }
    
    var lastMonthCo2: Double = 0 {
        didSet {
            self.lastMonthLabel.text = "\(lastMonthCo2)"
        }
    }
    
    var lastRecorded: Date? {
        didSet {
            if let date = lastRecorded {
                self.lastRecordedLabel.text = "Last Recorded On: \(date.toString(withFormat: "MM/yy"))"
            } else {
                let month = Date().toString(withFormat: "MMMM")
                self.lastRecordedLabel.text = "Record \(month) Bill"
            }
        }
    }
    
    var leftTitle: String = "Total CO2" {
        didSet {
            self.leftTitleLabel.text = leftTitle
        }
    }
    
    var rightTitle: String = "Last Month" {
        didSet {
            self.rightTitleLabel.text = rightTitle
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        roundedView.layer.cornerRadius = 20
        
        self.selectionStyle = .none
    }
}
