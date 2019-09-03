//
//  LogTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/30/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class LogTableViewCell: UITableViewCell, CustomCell {
    static var reuseIdentifier = "LogCell"
    
    typealias DataKeys = RequiredKeys
    
    enum RequiredKeys: String {
        case source = "source"
    }
    
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
    
    func loadData(_ data: [String : Any]) {
        guard let source = data[RequiredKeys.source.rawValue] as? CarbonSource else { return }
        
        self.title = source.name
        self.month = source.lastRecorded
        self.icon = source.sourceType.icon
    }
}
