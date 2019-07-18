//
//  appearance.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Material

extension UIFont {
    static let navigationTitle = UIFont(name: "Roboto-Black", size: 36)!
    static let header = UIFont(name: "Roboto-Black", size: 30)!
    static let label = UIFont(name: "Roboto-Regular", size: UIFont.labelFontSize)!
    static let button = UIFont(name: "Roboto-Regular", size: UIFont.buttonFontSize)!
    static let tabItemTitle = UIFont(name: "Roboto-Regular", size: 12)!
}

struct Colors {
    static let green = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
    static let darkGreen = UIColor(red: 45/255, green: 191/255, blue: 122/255, alpha: 1.0)
    static let red = UIColor(red:231/255, green: 76/255, blue:60/255, alpha:1.0)
    static let blue = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
    static let purple = UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0)
    static let grey = UIColor(red: 127/255, green: 140/255, blue: 141/255, alpha: 1.0)
    
    static let primary = green
    static let secondary = darkGreen
    static let text = grey
    
    static let options = [green, red, blue, purple, darkGreen]
}

extension Icon {
    static let logo_white = UIImage(named: "plant")!
    static let electric_white = UIImage(named: "Lightning_Bolt_White")!
    static let water_white = UIImage(named: "Water-Drop")!
    static let smoke_white = UIImage(named: "Smoke")!
    static let info_white = UIImage(named: "Information-256")!
    static let fire_white = UIImage(named: "Fire")!
    static let road_white = UIImage(named: "Road")!
    
    static let chart_green = UIImage(named: "Chart_Green")!
    static let lock = UIImage(named: "Lock")!
    static let person = UIImage(named: "Person")!
    
    static let electric_emblem = UIImage(named:"electric_emblem")!
    static let water_emblem = UIImage(named:"water_emblem")!
    static let leaf_emblem = UIImage(named:"Leaf_Emblem")!
    static let fire_emblem = UIImage(named:"fire_emblem")!
    static let road_emblem = UIImage(named:"road_emblem")!
}
