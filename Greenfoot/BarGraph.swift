//
//  BarGraph.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/21/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import Charts

class BarGraph: BarChartView {
    private var labels: [String] = []
    
    func loadData(_ data:[Date: Double], labeled label:String) {
        self.noDataText = "NO DATA"
        self.noDataTextColor = UIColor.white.withAlphaComponent(0.8)
        self.noDataFont = UIFont(name: "DroidSans", size: 35.0)
        
        //Creates the corner radius
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        self.backgroundColor = Colors.green
        
        if data.keys.count == 0 {
            return
        }
        
        //Covert the dictionary into two arrays ordered in ascending dates
        var dates:[Date] = Array(data.keys)
        dates.sort(by: { (date1, date2) -> Bool in
            return date1.compare(date2) == ComparisonResult.orderedAscending })
        
        var points: [Double] = []
        labels = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        var hasNegative = false
        
        for date in dates {
            let point = data[date]!
            
            if !hasNegative {
                hasNegative = (point < 0)
            }
            
            points.append(point)
            labels.append(formatter.string(from: date))
        }
        
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<points.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: points[i])
            dataEntries.append(dataEntry)
        }
        
        //You want to show 6 bars on screen, so if there are fewer points than that, add dummy bars
        if points.count < 6 {
            for i in points.count..<6 {
                let dataEntry = BarChartDataEntry(x: Double(i), y: 0)
                dataEntries.append(dataEntry)
            }
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: label)
        let chartData = BarChartData(dataSet: chartDataSet)
        
        chartData.barWidth = fixedToPercentWidth(35, withSpacing: 25, numberOfBars: points.count)
        
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        self.data = chartData
        
        //Design the chart
        self.chartDescription?.text = ""
        chartDataSet.colors = [UIColor.white.withAlphaComponent(0.5)]
        
        self.legend.enabled = false
        self.rightAxis.enabled = false
        
        self.xAxis.drawGridLinesEnabled = false
        self.xAxis.labelPosition = .bottom
        self.xAxis.axisLineColor = UIColor.clear
        self.xAxis.labelTextColor = UIColor.white.withAlphaComponent(0.8)
        
        self.leftAxis.gridColor = UIColor.white.withAlphaComponent(0.5)
        self.leftAxis.labelTextColor = UIColor.white
        self.leftAxis.labelFont = UIFont.boldSystemFont(ofSize: 8)
        self.leftAxis.axisLineColor = UIColor.clear
        
        if let max = points.max() {
            print("Maximum on Y axis \(max)")
            self.leftAxis.axisMaximum = 10 * ceil(max / 10.0)
        }
        
        if hasNegative {
            let xAxisLine = ChartLimitLine(limit: 0.0, label: "")
            xAxisLine.lineColor = UIColor.white
            self.leftAxis.addLimitLine(xAxisLine)
        }
        
        //Adds some padding
        self.extraTopOffset = 10
        self.extraBottomOffset = 10
        
        self.data?.setDrawValues(false)
        self.doubleTapToZoomEnabled = false
        //self.setScaleMinima(10, scaleY: 1)
        
        self.animate(xAxisDuration: 1.0, yAxisDuration: 2.0, easingOption: .linear)
    }
    
    func addDataPoint(labeled label:String, value: Double, atX x: Double) {
        let newEntry = BarChartDataEntry(x: x, y: value)
        if let set = self.data?.dataSets[0] {
            for i in Int(x)..<set.entryCount {
                set.entryForIndex(i)?.x = x + Double(i) + 1
            }
            if set.entryCount <= 6 {
                let _ = set.removeLast()
            }
            let _ = set.addEntryOrdered(newEntry)
            
            //print("Maximum on Y axis \(max)")
            self.leftAxis.axisMaximum = 10 * ceil(set.yMax / 10.0)
            (self.data as! BarChartData).barWidth = fixedToPercentWidth(35, withSpacing: 25, numberOfBars: set.entryCount)
            
            insertLabel(label, atPosition: x)
            
            self.notifyDataSetChanged()

        } else {
            let newData = [Date.monthFormat(string: label) : value]
            self.loadData(newData, labeled: "EP")
        }
    }
    
    private func insertLabel(_ newLabel:String, atPosition x:Double) {
        labels.insert(newLabel, at: Int(x))
        self.xAxis.setLabelCount(labels.count, force: true)
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
    }
    
    private func fixedToPercentWidth(_ fixed: Double, withSpacing spacing:Double, numberOfBars barNum: Int) -> Double {
        //print("Trying to size \(barNum) bars of width \(fixed) and spacing \(spacing)")
        let viewportWidth = self.width
        //print("Viewport: \(viewportWidth)")
        
        let totalSpace = fixed * Double(barNum) + spacing * Double(barNum - 1)
        //print("Total Space: \(totalSpace)")
        
        self.setScaleMinima(CGFloat(totalSpace)/viewportWidth, scaleY: 1.0)
        
        return fixed * Double(barNum)/totalSpace
    }
}