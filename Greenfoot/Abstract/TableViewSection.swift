//
//  TableViewSection.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

protocol CustomCell {
    static var reuseIdentifier: String {get}
    func loadData(_ data:[String: Any])
}

class TableViewSection {
    var header: UIView?
    var footer: UIView?
    
    var headerHeight:CGFloat = 0
    var footerHeight:CGFloat = 0
    
    var cellType: CustomCell.Type
    var rowCount: Int = 0
    var rowHeight: CGFloat = 0
    
    var data:[[String:Any]]
    
    var title:String? {
        didSet {
            if self.title != nil {
                initHeader()
            } else {
                header = nil
            }
        }
    }
    
    init(withData data:[[String:Any]], cellType type: CustomCell.Type) {
        self.data = data
        self.cellType = type
        self.rowCount = data.count
    }
    
    convenience init(titled title: String, withData data:[[String:Any]], cellType type: CustomCell.Type) {
        self.init(withData: data, cellType: type)
        self.title = title
    }
    
    private func initHeader() {
        let headerView = UIView()
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.textColor = .black
        label.font = UIFont.header
        
        label.text = self.title
        
        headerView.addSubview(label)
        
        label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        headerView.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10).isActive = true
        label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10).isActive = true
        headerView.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 10).isActive = true
        
        self.header = headerView
    }
}
