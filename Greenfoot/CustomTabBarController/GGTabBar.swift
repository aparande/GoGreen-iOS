//
//  GGTabBar.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class GGTabBar: UITabBar {

    var gg_items = [GGTabBarItem]()
    var estimatedHeight: CGFloat = 49
    
    convenience init(items: [GGTabBarItem]) {
        self.init()
        gg_items = items
        translatesAutoresizingMaskIntoConstraints = false
        self.isTranslucent = false
        
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = Colors.green
        self.barTintColor = Colors.green
        
        if gg_items.count == 0 { return }
        
        var lastAnchor = self.leadingAnchor
        
        var previousItem: GGTabBarItem?
        
        for item in gg_items {
            item.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(item)
            
            item.leadingAnchor.constraint(equalTo: lastAnchor).isActive = true
            item.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
            
            if item.itemHeight != 0 {
                item.heightAnchor.constraint(equalToConstant: item.itemHeight).isActive = true
            } else {
                item.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            }
            
            lastAnchor = item.trailingAnchor
            
            guard let prev = previousItem else {
                previousItem = item
                continue
            }
            
            prev.widthAnchor.constraint(equalTo: item.widthAnchor).isActive = true
            previousItem = item
        }
        
        lastAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }
}
