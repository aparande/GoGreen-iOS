//
//  BarGraphTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class BarGraphTableViewCell: UITableViewCell {
    @IBOutlet weak var graph: BarGraph!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        graph.isUserInteractionEnabled = false
    }
}
