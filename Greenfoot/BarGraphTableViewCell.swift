//
//  BarGraphTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class BarGraphTableViewCell: UITableViewCell, CustomCell {
    static let reuseIdentifier = "GraphCell"
    
    enum RequiredKeys: String {
        case points = "points"
        case unit = "unit"
    }
    
    @IBOutlet weak var graph: BarGraph!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        graph.isUserInteractionEnabled = false
    }
    
    func loadData(_ data: [String : Any]) {
        guard let points = data[RequiredKeys.points.rawValue] as? [Measurement] else { return }
        guard let unit = data[RequiredKeys.unit.rawValue] as? String else { return }
        
        self.graph.loadDataFrom(array: points, labeled: unit)
    }
}
