//
//  BarGraphTableViewSection.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

class BarGraphTableViewSection: TableViewSection {
    init(points: [Measurement], unit: CarbonUnit) {
        let data:[String:Any] = [
            BarGraphTableViewCell.RequiredKeys.points.rawValue:points,
            BarGraphTableViewCell.RequiredKeys.unit.rawValue: unit.name
        ]
        super.init(withData: [data], cellType: BarGraphTableViewCell.self)
        commonInit()
    }
    
    init(titled title: String, points: [Measurement], unit: CarbonUnit) {
        let data:[String:Any] = [
            BarGraphTableViewCell.RequiredKeys.points.rawValue:points,
            BarGraphTableViewCell.RequiredKeys.unit.rawValue: unit.name
        ]
        
        super.init(withData: [data], cellType: BarGraphTableViewCell.self)
        
        self.title = title
        self.headerHeight = 50
        commonInit()
    }
    
    private func commonInit() {
        self.rowHeight = 200
    }
}
