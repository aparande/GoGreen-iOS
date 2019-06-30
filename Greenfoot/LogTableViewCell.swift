//
//  LogTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/30/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class LogTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var recordedLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var roundedView: UIView!
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    var month: Date? {
        didSet {
            guard let date = month else {
                recordedLabel.text = "Not Recorded"
                return
            }
            
            let monthString = Date.monthFormat(date: date)
            recordedLabel.text = "Last Recorded On: \(monthString)"
        }
    }
    
    var icon: UIImage = Icon.logo_white {
        didSet {
            iconView.image = icon
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        roundedView.layer.cornerRadius = 20
    }
}
