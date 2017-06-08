//
//  InputToolbar.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class InputToolbar: UIToolbar {
    var rightButton: UIBarButtonItem?
    var leftButton: UIBarButtonItem?
    let centerField: UITextField
    
    init(left: Any?, right: Any?, color: UIColor?) {
        var buttons: [UIBarButtonItem] = []
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        if let image = left as? UIImage {
            self.leftButton = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
            buttons.append(leftButton!)
        }
        
        if let text = left as? String {
            self.leftButton = UIBarButtonItem(title: text, style: .plain, target: nil, action: nil)
            buttons.append(leftButton!)
        }
        
        centerField = UITextField(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width/3, height: 44))
        centerField.font = UIFont(name: "Droid Sans", size: 30.0)
        centerField.textAlignment = .center
        let center = UIBarButtonItem(customView: centerField)
        
        buttons.append(flexSpace)
        buttons.append(center)
        buttons.append(flexSpace)
        
        if let image = right as? UIImage {
            self.rightButton = UIBarButtonItem(image: image, style: .plain, target: nil, action: nil)
            buttons.append(rightButton!)
        }
        
        if let text = right as? String {
            self.rightButton = UIBarButtonItem(title: text, style: .plain, target: nil, action: nil)
            buttons.append(rightButton!)
        }
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        
        barStyle = .default
        items = buttons
        
        if let _ = color {
            backgroundColor = color
            barTintColor = color
            centerField.textColor = UIColor.white
            leftButton?.tintColor = UIColor.white
            rightButton?.tintColor = UIColor.white
        }
        
        sizeToFit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
