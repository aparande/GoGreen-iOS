//
//  GGTabController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class GGTabController: UITabBarController {

    var gg_tabBar: GGTabBar!
    
    private var gg_tabBarHeight: CGFloat = 49
    
    private var normalColor: UIColor = UIColor.white
    private var selectedColor: UIColor = UIColor.white
    
    override var selectedIndex: Int {
        didSet {
            for item in gg_tabBar.gg_items {
                item.color = (selectedIndex == item.tag) ? selectedColor : normalColor
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
    }
    
    func setTabBar(items: [GGTabBarItem], height: CGFloat = 49) {
        guard items.count > 0 else { return }
        
        gg_tabBar = GGTabBar(items: items)
        guard let bar = gg_tabBar else { return }
        
        view.addSubview(bar)
        
        bar.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor).isActive = true
        bar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        bar.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        gg_tabBarHeight = height
        bar.heightAnchor.constraint(equalToConstant: gg_tabBarHeight).isActive = true
        for i in 0 ..< items.count {
            items[i].tag = i
            items[i].addTarget(self, action: #selector(switchTab), for: .allTouchEvents)
            
            //items[i].color = normalColor
        }
    }
    
    @objc func switchTab(button: UIButton) {
        selectedIndex = button.tag
    }

}
