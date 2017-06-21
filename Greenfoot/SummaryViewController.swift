//
//  ViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import Charts

class SummaryViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var pointLabel:UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var barChart: BarChartView!
    @IBOutlet weak var pieChart: PieChartView!
    
    private var monthlyEP:[Date: Double] = [:]
    private var epBreakdown:[String: Double] = [:]
    private var viewFrame: CGRect!
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepToolbar()
        
        let shareButton = IconButton(image: Icon.cm.share, tintColor: UIColor.white)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        navigationItem.rightViews = [shareButton]
        
        let viewHeight = self.view.frame.height - UIApplication.shared.statusBarFrame.height - (self.navigationController?.navigationBar.frame.height)!-(self.tabBarController?.tabBar.frame.size.height)!

        viewFrame = CGRect(origin: self.view.frame.origin, size: CGSize(width: self.view.frame.width, height: viewHeight))
        self.scrollView.contentSize = CGSize(width: viewFrame.width, height: viewHeight*2)
        
        let subViews = UINib.init(nibName: "SummaryView", bundle: nil).instantiate(withOwner: self, options: nil) as! [UIView]
        
        subViews[0].frame = viewFrame!
        subViews[0].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showGraph)))
        self.scrollView.addSubview(subViews[0])
        
        let newOrigin = CGPoint(x:0, y:viewHeight)
        subViews[1].frame = CGRect(origin: newOrigin, size: viewFrame!.size)
        subViews[1].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showEmblem)))
        self.scrollView.addSubview(subViews[1])
        
        //Makes sure the scrollview fits the screen and doesn't allow vertical scrolling
        self.automaticallyAdjustsScrollViewInsets = false
        
        let modal = GreenfootModal.sharedInstance
        pointLabel.text = "\(modal.totalEnergyPoints)"
        
        for (key, data) in modal.data {
            for (month, value) in data.getEPData() {
                if let ep = monthlyEP[month] {
                    monthlyEP[month] = ep + Double(value)
                } else {
                    monthlyEP[month] = Double(value)
                }
            }
            
            if data.energyPoints != 0 {
                epBreakdown[key] = Double(data.energyPoints)
            }
        }
        
        barChart.delegate = self
        barChart.loadData(monthlyEP, labeled: "EP")
        
        pieChart.loadData(epBreakdown, labeled: "Breakdown")
    }
    
    func showGraph() {
        let newOrigin = CGPoint(x: 0, y:viewFrame.height)
        self.scrollView.scrollRectToVisible(CGRect(origin: newOrigin, size: self.viewFrame!.size), animated: true)
    }
    
    func showEmblem() {
        self.scrollView.scrollRectToVisible(CGRect(origin: CGPoint.zero, size: self.viewFrame!.size), animated: true)
    }
    
    func share() {
        let message = "I earned "+pointLabel.text!+" Energy Points on Greenfoot! How many do you have?"
        let activityView = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityView.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .openInIBooks, .postToFlickr, .postToVimeo, .print, .saveToCameraRoll]
        self.present(activityView, animated: true, completion: nil)
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print("\(entry)")
    }
}

extension UIViewController {
    func prepToolbar() {
        //let menuButton = IconButton(image: Icon.cm.menu)
        //menuButton.addTarget(navigationDrawerController, action: #selector(NavigationDrawerController.openLeftView(velocity:)), for: .touchUpInside)
        //navigationItem.leftViews = [menuButton]
        
        let logo = UIImageView(image: Icon.logo_white)
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        //menuButton.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
    }
}

extension BarChartView {
    func loadData(_ data:[Date: Double], labeled label:String) {
        self.noDataText = "NO DATA"
        self.noDataTextColor = UIColor.white.withAlphaComponent(0.8)
        self.noDataFont = UIFont(name: "DroidSans", size: 35.0)
        
        //Creates the corner radius
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        
        if data.keys.count == 0 {
            return
        }
        
        //Covert the dictionary into two arrays ordered in ascending dates
        var dates:[Date] = Array(data.keys)
        dates.sort(by: { (date1, date2) -> Bool in
            return date1.compare(date2) == ComparisonResult.orderedAscending })
        
        var labels: [String] = []
        var points: [Double] = []
        
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
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: label)
        let chartData = BarChartData(dataSet: chartDataSet)
        
        chartData.barWidth = fixedToPercentWidth(30, withSpacing: 25, numberOfBars: points.count)
    
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        self.data = chartData
        
        //Design the chart
        self.chartDescription?.text = ""
        chartDataSet.colors = [UIColor.white.withAlphaComponent(0.5)]
        self.backgroundColor = Colors.green
        
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
            self.leftAxis.axisMaximum = 10 * ceil(max / 10.0)
        }
        
        let xAxisLine = ChartLimitLine(limit: 0.0, label: "")
        xAxisLine.lineColor = UIColor.white
        self.leftAxis.addLimitLine(xAxisLine)
        
        //Adds some padding
        self.extraTopOffset = 10
        self.extraBottomOffset = 10
        
        self.data?.setDrawValues(false)
        self.doubleTapToZoomEnabled = false
        //self.setScaleMinima(10, scaleY: 1)
        
        self.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
    }
    
    private func fixedToPercentWidth(_ fixed: Double, withSpacing spacing:Double, numberOfBars barNum: Int) -> Double {
        let viewportWidth = self.width
        
        let totalSpace = fixed * Double(barNum) + spacing * Double(barNum - 1)
        
        self.setScaleMinima(CGFloat(totalSpace)/viewportWidth, scaleY: 1.0)
        
        return fixed * Double(barNum)/totalSpace
    }
}

extension PieChartView {
    func loadData(_ data:[String:Double], labeled label:String) {
        //Covert the dictionary into two arrays ordered in ascending dates
        var points:[Double] = []
        var labels:[String] = []
        
        for (name, point) in data {
            points.append(point)
            labels.append(name)
        }
        
        var entries:[ChartDataEntry] = []
        for i in 0..<points.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: points[i])
            entries.append(dataEntry)
        }
        
        let pieChartDataSet = PieChartDataSet(values: entries, label: label)
        pieChartDataSet.sliceSpace = 5.0
        
        let pieChartData = PieChartData(dataSet: pieChartDataSet)
        pieChartData.setValueFormatter(DefaultValueFormatter(block: {
            (value, entry, index, _) in
            return "\(value)\n"+labels[Int(entry.x)]
        }))
        
        self.legend.enabled = false
        self.chartDescription?.text = ""

        self.data = pieChartData
        
        var colors: [UIColor] = []
        for i in 0..<points.count {
            switch labels[i] {
            case "Electric":
                colors.append(Colors.green)
                break
            case "Water":
                colors.append(Colors.blue)
                break
            case "Gas":
                colors.append(Colors.red)
                break
            case "Emissions":
                colors.append(Colors.purple)
                break
            default:
                colors.append(Colors.darkGreen)
                break
            }
        }
        pieChartDataSet.colors = colors
        
        self.extraTopOffset = 0
        self.extraBottomOffset = 0
        
        self.minOffset = 0
        
        self.rotationEnabled = false
        self.holeRadiusPercent = 0.25
        self.transparentCircleRadiusPercent = 0.3
        
        self.animate(xAxisDuration: 2.0, easingOption: .easeInCirc)
    }
}

