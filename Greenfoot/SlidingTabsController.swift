//
//  SlidingTabsController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 11/16/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Material

class SlidingTabsController: TabsController {
    var titles:[String]
    
    init(viewControllers: [UIViewController], withTitles titles: [String], selectedIndex: Int = 0) {
        self.titles = titles
        super.init(viewControllers: viewControllers, selectedIndex: selectedIndex)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.titles = []
        super.init(coder: aDecoder)
    }
    
    override func prepare() {
        super.prepare()
        
        self.tabBarAlignment = .top
        self.tabBar.backgroundColor = Colors.green
        self.displayStyle = .partial
        
        self.tabBar.tintColor = .white
        self.tabBar.lineColor = .white
        
        for i in 0 ..< self.titles.count {
            let tabItem = self.tabBar.tabItems[i]
            
            tabItem.setTitle(self.titles[i], for: .normal)
            tabItem.setTitleColor(.white, for: .selected)
            tabItem.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .normal)
            
            tabItem.titleLabel?.font = UIFont.boldButton
        }
    }
}
