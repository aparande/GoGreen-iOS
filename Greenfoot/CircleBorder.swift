//
//  CircleBorder.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class CircleBorder: CALayer {
    var lineColor: CGColor = UIColor.white.cgColor
    var lineWidth: CGFloat = 2.0
    
    override func draw(in ctx: CGContext) {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        ctx.beginPath()
        ctx.setStrokeColor(lineColor)
        ctx.setLineWidth(lineWidth)
        ctx.addArc(center: center, radius: bounds.height / 2 - lineWidth, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false)
        ctx.drawPath(using: .stroke)
    }
    
    override class func needsDisplay(forKey key:String) -> Bool {
        if key == "lineColor" || key == "lineWidth" {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
}
