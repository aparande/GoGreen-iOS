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
        basicSetup()
        
        if data.keys.count == 0 {
            self.data = nil
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
        
        buildGraphWith(points: points, legendLabel: label, hasNegative: hasNegative)
    }
    
    func loadData(_ values:[String: Double]) {
        basicSetup()
        
        if values.keys.count == 0 {
            self.data = nil
            return
        }
        
        //Covert the dictionary into two arrays ordered in ascending dates
        let dates:[String] = Array(values.keys)
        
        var points: [Double] = []
        labels = []
        
        var hasNegative = false
        
        for date in dates {
            let point = values[date]!
            
            if !hasNegative {
                hasNegative = (point < 0)
            }
            
            points.append(point)
            labels.append(date)
        }
        
        buildGraphWith(points: points, legendLabel: nil, hasNegative: hasNegative)
    }
    
    private func basicSetup() {
        self.noDataText = "NO DATA"
        self.noDataTextColor = UIColor.white.withAlphaComponent(0.8)
        self.noDataFont = UIFont(name: "DroidSans", size: 35.0)
        
        //Creates the corner radius
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.backgroundColor = Colors.green
    }
    
    private func buildGraphWith(points: [Double], legendLabel:String?, hasNegative: Bool) {
        var dataEntries: [BarChartDataEntry] = []
        for i in 0..<points.count {
            var point = points[i]
            if points[i] == 0 {
                point = 0.15
            }
            let dataEntry = BarChartDataEntry(x: Double(i), y: point)
            dataEntries.append(dataEntry)
        }
        
        //You want to show 6 bars on screen. If there are less than 7 points, then add at least 1 dummy bar to prevent strange label issues.
        if points.count < 7 {
            for i in points.count..<7 {
                let dataEntry = BarChartDataEntry(x: Double(i), y: 0)
                dataEntries.append(dataEntry)
            }
        }
        
        let chartDataSet: BarChartDataSet
        if let label = legendLabel {
            chartDataSet = BarChartDataSet(values: dataEntries, label: label)
            
            self.legend.enabled = true
            self.legend.textColor = UIColor.white
            self.legend.font = UIFont.boldSystemFont(ofSize: 10)
            
            //Adds some padding
            self.setViewPortOffsets(left: 30, top: 15, right: 0, bottom: 40)
        } else {
            chartDataSet = BarChartDataSet(values: dataEntries, label: "")
            
            self.legend.enabled = false
            //Adds some padding
            self.setViewPortOffsets(left: 30, top: 20, right: 0, bottom: 20)
        }
        
        let chartData = BarChartData(dataSet: chartDataSet)
        
        let chartFormatter = BarChartFormatter(labels: labels)
        let xAxis = XAxis()
        xAxis.valueFormatter = chartFormatter
        self.xAxis.valueFormatter = xAxis.valueFormatter
        self.xAxis.granularityEnabled = true
        self.xAxis.granularity = 1
        
        self.data = chartData
        
        chartData.barWidth = fixedToPercentWidth(35, withSpacing: 25, numberOfBars: points.count)
        
        //Design the chart
        self.chartDescription?.text = ""
        chartDataSet.colors = [UIColor.white.withAlphaComponent(0.5)]
        
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
            if max == 0 {
                self.leftAxis.axisMaximum = 5
            } else {
                let power = floor(log10(max))
                switch power {
                case 0:
                    if max > 5 {
                        self.leftAxis.axisMaximum = 10
                    } else {
                        self.leftAxis.axisMaximum = 5
                    }
                default:
                    let power = floor(log10(max))
                    let multiplier = pow(10, power)
                    self.leftAxis.axisMaximum = multiplier * ceil(max / multiplier)
                }
            }
        }
        
        if hasNegative {
            let line = ChartLimitLine(limit: 0.0, label: "")
            line.lineColor = UIColor.white
            self.leftAxis.addLimitLine(line)
            
            if let min = points.min() {
                //print("Minimum on Y axis \(min)")
                self.leftAxis.axisMinimum = 10 * floor(min/10.0)
                
                if floor(log10(abs(min))) == 0 {
                    self.leftAxis.axisMinimum = -5
                }
            }
            
            if points.count == 1 {
                self.leftAxis.axisMaximum = 0.0
            }
        } else {
            self.leftAxis.axisMinimum = 0.0
            self.leftAxis.removeAllLimitLines()
        }
        
        self.data?.setDrawValues(false)
        self.doubleTapToZoomEnabled = false
        //self.setScaleMinima(10, scaleY: 1)
        self.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .linear)
        self.moveViewToX(Double(points.count))
    }
    
    private func fixedToPercentWidth(_ fixed: Double, withSpacing spacing:Double, numberOfBars barNum: Int) -> Double {
        //print("Trying to size \(barNum) bars of width \(fixed) and spacing \(spacing)")
        //let viewportWidth = self.frame.width
        let viewportWidth = UIScreen.main.bounds.width - 2 * 23
        //print("Viewport: \(viewportWidth)")
        
        let totalSpace = fixed * Double(barNum) + spacing * Double(barNum - 1)
        //print("Total Space: \(totalSpace)")
        
        self.setScaleMinima(CGFloat(totalSpace)/viewportWidth, scaleY: 1.0)
        
        return fixed * Double(barNum)/totalSpace
    }
}

extension HorizontalBarChartView {
    func loadData(_ data:[String: Double], labeled label:String) {
        //Creates the corner radius
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        self.backgroundColor = Colors.green
        
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
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: label)
        let chartData = BarChartData(dataSet: chartDataSet)
        //chartData.setValueTextColor(UIColor.white)
        //chartData.setValueFont(UIFont.boldSystemFont(ofSize: 8))
        
        let chartFormatter = BarChartFormatter(labels: labels)
        let xAxis = XAxis()
        xAxis.valueFormatter = chartFormatter
        self.xAxis.valueFormatter = xAxis.valueFormatter
        
        self.data = chartData
        
        //Design the chart
        self.chartDescription?.text = ""
        chartDataSet.colors = [UIColor.white.withAlphaComponent(0.5)]
        
        //self.legend.enabled = false
        self.legend.textColor =  UIColor.white
        self.legend.font = UIFont.boldSystemFont(ofSize: 8)
        self.rightAxis.enabled = false
        
        self.xAxis.drawGridLinesEnabled = false
        self.xAxis.labelPosition = .bottomInside
        self.xAxis.axisLineColor = UIColor.clear
        self.xAxis.labelTextColor = UIColor.white
        self.xAxis.labelCount = labels.count
        
        self.leftAxis.gridColor = UIColor.white.withAlphaComponent(0.5)
        self.leftAxis.labelTextColor = UIColor.white
        self.leftAxis.labelFont = UIFont.boldSystemFont(ofSize: 8)
        self.leftAxis.axisLineColor = UIColor.clear
        
        if let max = points.max() {
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
        }
        
        self.leftAxis.axisMinimum = 0
        
        //Adds some padding
        self.extraTopOffset = 10
        self.extraBottomOffset = -10
        self.extraRightOffset = 15
        
        self.data?.setDrawValues(false)
        self.doubleTapToZoomEnabled = false
        //self.setScaleMinima(10, scaleY: 1)
        
        self.animate(xAxisDuration: 1.0, yAxisDuration: 1.0, easingOption: .linear)
    }
    
    func showError(_ error: String) {
        self.noDataText = error
        self.noDataTextColor = UIColor.white.withAlphaComponent(0.8)
        self.noDataFont = UIFont(name: "DroidSans", size: 20.0)
        
        //Creates the corner radius
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        self.backgroundColor = Colors.green
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
