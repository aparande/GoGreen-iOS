//
//  GGTabButton.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/13/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class GGTabBarItem: UIButton {
    
    var itemHeight: CGFloat = 0
    var lock = false
    var roundedTop: Bool = false
    var estimatedHeight: CGFloat = 49.0
    
    var color: UIColor = UIColor.white {
        didSet {
            guard lock == false else { return }
            iconImageView.tintColor = color
            textLabel.textColor = color
        }
    }
    
    private let iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.tabItemTitle
        label.textAlignment = .center
        return label
    }()
    
    convenience init(icon: UIImage, title:String, isRounded: Bool) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.image = icon.resize(toWidth: 30)?.resize(toHeight: 30)?.withRenderingMode(.alwaysTemplate)
        textLabel.text = title
        self.roundedTop = isRounded
        
        iconImageView.tintColor = color
        textLabel.textColor = color
        
        setupViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if roundedTop {
            let roundedTopLayer = RoundedTop()
            
            let coloredTopLayer = ColoredTop()
            self.layer.insertSublayer(coloredTopLayer, at: 0)
            
            coloredTopLayer.frame = self.bounds
            coloredTopLayer.yPos = self.bounds.height - self.estimatedHeight
            
            self.layer.insertSublayer(roundedTopLayer, at: 1)
            
            roundedTopLayer.frame = self.bounds
            roundedTopLayer.centerY = self.bounds.height - self.estimatedHeight
            
            roundedTopLayer.setNeedsDisplay()
            coloredTopLayer.setNeedsDisplay()
        } else {
            let coloredTopLayer = ColoredTop()
            self.layer.insertSublayer(coloredTopLayer, at: 0)
            
            coloredTopLayer.frame = self.bounds
            coloredTopLayer.setNeedsDisplay()
        }
    }
    
    private func setupViews() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(iconImageView)
        self.addSubview(textLabel)
        
        let topConstant: CGFloat = (self.roundedTop) ? 10 : 4
        
        iconImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: topConstant).isActive = true
        iconImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor).isActive = true
        
        iconImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20).isActive = true
        
        textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2).isActive = true
        textLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
    }
}

private class RoundedTop: CALayer {
    var lineColor: CGColor = UIColor.white.cgColor
    var fillColor: CGColor = Colors.green.cgColor
    var lineWidth: CGFloat = 2.0
    var centerY: CGFloat = 0
    
    override func draw(in ctx: CGContext) {
        let center = CGPoint(x: self.bounds.center.x, y: centerY)
        let radius = self.bounds.width / 4 - lineWidth
        
        ctx.beginPath()
        ctx.setStrokeColor(lineColor)
        ctx.setFillColor(fillColor)
        ctx.setLineWidth(lineWidth)
        ctx.addArc(center: center, radius: radius, startAngle: CGFloat.pi, endAngle: 2 * CGFloat.pi, clockwise: false)
        ctx.drawPath(using: .fillStroke)
        ctx.addArc(center: center, radius: radius, startAngle: 2 * CGFloat.pi, endAngle: 3 * CGFloat.pi, clockwise: false)
        ctx.drawPath(using: .fill)
    }
    
    override class func needsDisplay(forKey key:String) -> Bool {
        if key == "lineColor" || key == "lineWidth" || key == "fillColor" {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
}

private class ColoredTop: CALayer {
    var lineColor: CGColor = UIColor.white.cgColor
    var lineWidth: CGFloat = 2.0
    var yPos: CGFloat = 0
    
    override func draw(in ctx: CGContext) {
        let left = CGPoint(x: 0, y: yPos + lineWidth / 2)
        let right = CGPoint(x: self.bounds.maxX, y: yPos + lineWidth / 2)
        
        
        ctx.beginPath()
        ctx.setStrokeColor(lineColor)
        ctx.setLineWidth(lineWidth)
        ctx.addLines(between: [left, right])
        ctx.drawPath(using: .fillStroke)
    }
    
    override class func needsDisplay(forKey key:String) -> Bool {
        if key == "lineColor" || key == "lineWidth" || key == "fillColor" {
            return true
        }
        
        return super.needsDisplay(forKey: key)
    }
}
