//
//  CircleIconButton.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/20/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Material

@IBDesignable
class RoundedIconButton: RaisedButton {
    @IBInspectable var cornerRadius: CGFloat = 15 {
        didSet {
            self.refreshCornerRadius()
        }
    }
    
    @IBInspectable var isCircle: Bool = false {
        didSet {
            self.refreshCornerRadius()
        }
    }
    
    @IBInspectable var icon: UIImage? {
        didSet {
            self.refreshImage()
        }
    }
    
    @IBInspectable var iconColor: UIColor = UIColor.white {
        didSet {
            self.refreshImage()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    override func prepareForInterfaceBuilder() {
        sharedInit()
    }
    
    private func sharedInit() {
        self.layer.masksToBounds = true
        self.clipsToBounds = false
        
        self.refreshImage()
        self.refreshCornerRadius()
    }
    
    private func refreshImage() {
        self.imageView?.tintColor = self.iconColor
        
        let tmp = icon?.withRenderingMode(.alwaysTemplate)
        self.setImage(tmp, for: .normal)
    }
    
    private func refreshCornerRadius() {
        print("Ooh Circular: \(isCircle)")
        if isCircle {
            print(self.layer.frame.height / 2)
            print(self.frame.height / 2)
            self.layer.cornerRadius = self.layer.frame.height / 2
        } else {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
