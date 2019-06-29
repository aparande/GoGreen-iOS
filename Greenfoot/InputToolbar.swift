//
//  InputToolbar.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

protocol InputToolbarDelegate {
    func leftTrigger()
    func rightTrigger()
}

class InputToolbar: UIToolbar {
    var rightButton: UIBarButtonItem?
    var leftButton: UIBarButtonItem?
    var centerField: UITextField!
    
    var inputDelegate: InputToolbarDelegate?
    
    var color: UIColor? {
        didSet {
            self.backgroundColor = self.color
            self.barTintColor = self.color
        }
    }
    
    var itemTint: UIColor? {
        didSet {
            centerField?.textColor = self.itemTint
            leftButton?.tintColor = self.itemTint
            rightButton?.tintColor = self.itemTint
        }
    }
    
    init(left: Any?, right: Any?, color: UIColor?) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        
        setUpCenterField()
        setLeftButton(left: left)
        setRightButton(right: right)
        
        barStyle = .default
        sizeToFit()
        
        if let newColor = color {
            self.color = newColor
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpCenterField()
        
        self.color = Colors.green
        self.itemTint = UIColor.white
        
        self.barStyle = .default
        self.isTranslucent = false
        
        sizeToFit()
    }
    
    func setLeftButton(left: Any?) {
        if let image = left as? UIImage {
            self.leftButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(clickLeft))
        }
        
        if let text = left as? String {
            self.leftButton = UIBarButtonItem(title: text, style: .plain, target: self, action: #selector(clickLeft))
        }
        
        if let button = self.leftButton {
            self.items?.insert(button, at: 0)
        }
        
        sizeToFit()
    }
    
    func setRightButton(right: Any?) {
        if let image = right as? UIImage {
            self.rightButton = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(clickRight))
        }
        
        if let text = right as? String {
            self.rightButton = UIBarButtonItem(title: text, style: .plain, target: self, action: #selector(clickRight))
        }
        
        if let button = self.rightButton {
            self.items?.append(button)
        }
        
        sizeToFit()
    }
    
    private func setUpCenterField() {
        var buttons: [UIBarButtonItem] = []
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        centerField = UITextField(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width/3, height: 44))
        centerField!.font = UIFont(name: "Droid Sans", size: 30.0)
        centerField!.textAlignment = .center
        let center = UIBarButtonItem(customView: centerField!)
        
        buttons.append(flexSpace)
        buttons.append(center)
        buttons.append(flexSpace)
        
        self.items = buttons
    }
    
    @objc private func clickRight() {
        self.inputDelegate?.rightTrigger()
    }
    
    @objc private func clickLeft() {
        self.inputDelegate?.leftTrigger()
    }
}
