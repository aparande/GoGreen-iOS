//
//  UtilityTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import BLTNBoard

protocol UtilityTableViewCellDelegate: BLTNPageItemDelegate {
    func showBulletin(for data: GreenData?)
    func viewGraph(for data: GreenData?)
    func listData(for data: GreenData?)
}

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
    
    private var hideSecondaryButtons:Bool = false {
        didSet {
            leftActionButton.alpha = (hideSecondaryButtons) ? 0 : 1
            rightActionButton.alpha = (hideSecondaryButtons) ? 0 : 1
        }
    }
    
    var data: GreenData? {
        didSet {
            configure(to: self.data)
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
    
    var owner: UtilityTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        roundedView.layer.cornerRadius = 20
        
        self.selectionStyle = .none
    }
    
    private func configure(to data:GreenData?) {
        self.titleLabel.text = data?.dataName
        
        if let date = data?.graphData.last?.month {
            self.lastRecordedLabel.text = "Last Recorded On: \(date.toString(withFormat: "MM/yy"))"
        } else {
            let month = Date().toString(withFormat: "MMMM")
            self.lastRecordedLabel.text = "Record \(month) Bill"
            self.hideSecondaryButtons = true
        }
    }
    @IBAction func primaryButtonClicked(_ sender: Any) {
        self.owner?.showBulletin(for: self.data)
    }
    
    @IBAction func leftButtonClicked(_ sender: Any) {
        self.owner?.listData(for: self.data)
    }
    
    @IBAction func rightButtonClicked(_ sender: Any) {
        self.owner?.viewGraph(for: self.data)
    }
}