//
//  BarGraph.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/21/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import Charts

extension BarChartView {
    func setXAxisLabels(to labels:[String]) {
        let chartFormatter = BarChartFormatter(labels: labels)
        let xAxis = XAxis()
        xAxis.valueFormatter = chartFormatter
        self.xAxis.valueFormatter = xAxis.valueFormatter
        
        self.xAxis.granularityEnabled = true
        self.xAxis.granularity = 1
    }
    
    func setNoDataText(to text:String) {
        self.noDataTextColor = UIColor.white.withAlphaComponent(0.8)
        self.noDataFont = UIFont.header
        self.noDataText = text
    }
    
    func styleBackground(withColor color: UIColor, cornerRadius: CGFloat) {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.backgroundColor = Colors.green
    }
    
    func fixedToPercentWidth(_ fixed: Double, withSpacing spacing:Double, numberOfBars barNum: Int) -> Double {
        //print("Trying to size \(barNum) bars of width \(fixed) and spacing \(spacing)")
        //let viewportWidth = self.frame.width
        let viewportWidth = UIScreen.main.bounds.width - 2 * 23
        //print("Viewport: \(viewportWidth)")
        
        let totalSpace = fixed * Double(barNum) + spacing * Double(barNum - 1)
        //print("Total Space: \(totalSpace)")
        
        self.setScaleMinima(CGFloat(totalSpace)/viewportWidth, scaleY: 1.0)
        
        return fixed * Double(barNum)/totalSpace
    }
    
    func fixedToPercentHeight(_ fixed: Double, withSpacing spacing:Double, numberOfBars barNum: Int) -> Double {
        //print("Trying to size \(barNum) bars of width \(fixed) and spacing \(spacing)")
        //let viewportWidth = self.frame.width
        let viewportWidth = self.viewPortHandler.chartHeight - 2 * 23
        
        let totalSpace = fixed * Double(barNum) + spacing * Double(barNum)
        //print("Total Space: \(totalSpace)")
        
        self.setScaleMinima(CGFloat(totalSpace)/viewportWidth, scaleY: 1.0)

        return fixed * Double(barNum)/totalSpace
    }
    
    func enableLegend() {
        self.legend.enabled = true
        self.legend.textColor = UIColor.white
        self.legend.font = UIFont.boldSystemFont(ofSize: 10)
        
        //Adds some padding
        self.setViewPortOffsets(left: 30, top: 15, right: 0, bottom: 40)
    }
    
    func disableLegend() {
        self.legend.enabled = false
        //Adds some padding
        self.setViewPortOffsets(left: 30, top: 20, right: 0, bottom: 20)
    }
    
    func styleAxes() {
        self.styleXAxis()
        self.styleYAxis()
    }
    
    private func styleXAxis() {
        self.xAxis.drawGridLinesEnabled = false
        self.xAxis.labelPosition = .bottom
        self.xAxis.axisLineColor = UIColor.clear
        self.xAxis.labelTextColor = UIColor.white.withAlphaComponent(0.8)
    }
    
    private func styleYAxis() {
        self.leftAxis.gridColor = UIColor.white.withAlphaComponent(0.5)
        self.leftAxis.labelTextColor = UIColor.white
        self.leftAxis.labelFont = UIFont.boldSystemFont(ofSize: 8)
        self.leftAxis.axisLineColor = UIColor.clear
    }
}

class BarChartFormatter: NSObject, IAxisValueFormatter {
    
    var labels: [String] = []
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if Int(value) >= labels.count {
            return ""
        } else {
            return labels[Int(value)]
        }
    }
    
    init(labels: [String]) {
        super.init()
        self.labels = labels
    }
}
