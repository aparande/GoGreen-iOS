//
//  HorizontalBarGraph.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/20/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import Charts

class HorizontalBarGraph: HorizontalBarChartView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        styleBackground(withColor: .green, cornerRadius: 10)
        self.chartDescription?.text = ""
        
        //Adds some padding
        self.extraTopOffset = 10
        self.extraBottomOffset = -10
        self.extraRightOffset = 15
        
        self.enableLegend()
        
        self.doubleTapToZoomEnabled = false
        self.rightAxis.enabled = false
    }
    
    func loadData(_ data:[String: Double], labeled label:String) {
        if data.keys.count == 0 {
            return
        }
        
        //Covert the dictionary into two arrays ordered in ascending dates
        var points: [Double] = []
        var labels: [String] = []
        
        for (key, value) in data {
            labels.append(key)
            points.append(value)
        }
        
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<points.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: points[i])
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: label)
        let chartData = BarChartData(dataSet: chartDataSet)
        
        chartData.barWidth = fixedToPercentHeight(50, withSpacing: 20, numberOfBars: points.count)
        
        self.data = chartData
        
        chartDataSet.colors = [UIColor.white.withAlphaComponent(0.5)]
        
        styleAxes()
        
        setXAxisLabels(to: labels)
        self.xAxis.labelCount = labels.count
        
        if let max = points.max() {
            scaleYAxis(to: max)
        }
    
        self.data?.setDrawValues(false)
        //self.setScaleMinima(10, scaleY: 1)
        
        self.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .linear)
    }
    
    private func scaleYAxis(to max: Double) {
        switch floor(log10(max)) {
        case 1:
            self.leftAxis.axisMaximum = 10 * ceil(max / 10.0)
            break
        case 2:
            self.leftAxis.axisMaximum = 100 * ceil(max / 100.0)
            break
        case 3:
            self.leftAxis.axisMaximum = 1000 * ceil(max / 1000.0)
            break
        default:
            self.leftAxis.axisMaximum = 10 * ceil(max / 10.0)
            break
        }
        
        self.leftAxis.axisMinimum = 0
    }
}
