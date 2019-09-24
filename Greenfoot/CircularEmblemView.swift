//
//  CircularEmblemView.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class CircularEmblemView: UIView {
    private var view: UIView!
    
    
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    
    
    @IBInspectable var value:Double = 0 {
        didSet {
            numberLabel.text = String(format: "%.2f", value)
        }
    }
    
    @IBInspectable var unit:String = "" {
        didSet {
            unitLabel.text = unit.uppercased()
        }
    }
    
    
    @IBInspectable var viewBorderColor: UIColor = UIColor.white {
        didSet {
            border.lineColor = viewBorderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2 {
        didSet {
            border.lineWidth = borderWidth
        }
    }
    
    let border = CircleBorder()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadViewFromNib()
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        border.frame = self.bounds
        //border.lineWidth = borderWidth
        //border.lineColor = viewBorderColor.cgColor
        border.setNeedsDisplay()
    }
    
    func commonInit() {
        self.layer.addSublayer(border)
    }
    
    func loadViewFromNib() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(view)
        self.view = view
    }
    
    func displayMeasurement(_ meas: Measurement) {
        (self.value, self.unit) = meas.display()
    }
}
