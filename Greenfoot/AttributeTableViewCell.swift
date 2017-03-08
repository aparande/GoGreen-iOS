//
//  AttributeTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class AttributeTableViewCell: UITableViewCell {

    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var dataPointLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setInfo(attribute:String, data:Int) {
        stepper.value = Double(data)
        attributeLabel.text = attribute
        dataPointLabel.text = "\(data)"
    }
    
    @IBAction func updateValue(_ sender: Any) {
        dataPointLabel.text = "\(stepper.value)"
    }

}
