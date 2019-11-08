//
//  DataLogTableViewSection.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

class DataLogTableViewSection: TableViewSection {
    private static func contructData(fromSources sources: [CarbonSource]) -> [[String:Any]] {
        var data:[[String:Any]] = []
        for source in sources {
            data.append([LogTableViewCell.RequiredKeys.source.rawValue: source])
        }
        return data
    }
    
    init(withSources sources:[CarbonSource]) {
        super.init(withData: DataLogTableViewSection.contructData(fromSources: sources), cellType: LogTableViewCell.self)
        
        commonInit()
    }
    
    convenience init(titled title: String, sources:[CarbonSource]) {
        self.init(withSources: sources)
        
        self.title = title
        self.headerHeight = 50
    }
    
    private func commonInit() {
        self.footer = UIView()
        self.footerHeight = 90.0
        
        self.rowHeight = 100.0
    }
}
