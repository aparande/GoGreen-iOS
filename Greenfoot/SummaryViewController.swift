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
    @IBOutlet weak var barChart: BarGraph!
    
    @IBOutlet weak var electricChart: HorizontalBarChartView!
    @IBOutlet weak var waterChart: HorizontalBarChartView!
    @IBOutlet weak var emissionsChart: HorizontalBarChartView!
    @IBOutlet weak var gasChart: HorizontalBarChartView!
    
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
        self.scrollView.contentSize = CGSize(width: viewFrame.width, height: viewHeight*3)
        
        let subViews = UINib.init(nibName: "SummaryView", bundle: nil).instantiate(withOwner: self, options: nil) as! [UIView]
        
        subViews[0].frame = viewFrame!
        subViews[0].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showGraph)))
        self.scrollView.addSubview(subViews[0])
        
        let newOrigin = CGPoint(x:0, y:viewHeight)
        subViews[1].frame = CGRect(origin: newOrigin, size: viewFrame!.size)
        subViews[1].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showEmblem)))
        self.scrollView.addSubview(subViews[1])
        
        let secondOrigin = CGPoint(x:0, y: viewHeight * 2)
        subViews[2].frame = CGRect(origin: secondOrigin, size: viewFrame!.size)
        self.scrollView.addSubview(subViews[2])
        
        //Makes sure the scrollview fits the screen and doesn't allow horizontal scrolling
        self.automaticallyAdjustsScrollViewInsets = false
        
        let modal = GreenfootModal.sharedInstance
        
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
        
        for (name, data) in GreenfootModal.sharedInstance.data {
            var dict = ["U.S": data.baseline]
            if let consumption = data.stateConsumption {
                let state = GreenfootModal.sharedInstance.locality!["State"]!
                dict[state] = consumption
            }
            
            if data.getGraphData().count != 0 {
                dict["You"] = data.averageMonthly
            }
            
            chartForData(named: name).loadData(dict, labeled: labelForData(named: name))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pointLabel.text = "\(GreenfootModal.sharedInstance.totalEnergyPoints)"
    }
    
    func showGraph() {
        let newOrigin = CGPoint(x: 0, y:viewFrame.height)
        self.scrollView.scrollRectToVisible(CGRect(origin: newOrigin, size: self.viewFrame!.size), animated: true)
    }
    
    func showEmblem() {
        let newOrigin = CGPoint(x: 0, y:viewFrame.height * 2)
        //self.scrollView.scrollRectToVisible(CGRect(origin: CGPoint.zero, size: self.viewFrame!.size), animated: true)
        for (name, data) in GreenfootModal.sharedInstance.data {
            var dict = ["U.S": data.baseline]
            if let consumption = data.stateConsumption {
                let state = GreenfootModal.sharedInstance.locality!["State"]!
                dict[state] = consumption
            }
            
            if data.getGraphData().count != 0 {
                dict["You"] = data.averageMonthly
            }
            
            chartForData(named: name).loadData(dict, labeled: labelForData(named: name))
        }
        
        self.scrollView.scrollRectToVisible(CGRect(origin: newOrigin, size: self.viewFrame!.size), animated: true)
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
    
    private func chartForData(named name: String) -> HorizontalBarChartView {
        switch name {
            case "Electric":
                return electricChart
            case "Water":
                return waterChart
            case "Emissions":
                return emissionsChart
            case "Gas":
                return gasChart
            default:
                return electricChart
        }
    }
    
    private func labelForData(named name:String) -> String {
        switch name {
            case "Electric":
                return "Monthly Electricity Consumption (kWh)"
            case "Water":
                return "Monthly Water Consumption (Gal)"
            case "Emissions":
                return "Monthly CO2 Emission (kg)"
            case "Gas":
                return "Monthly Gas Consumption (Therms)"
            default:
                return ""
        }
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
    
    func prepSegmentedToolbar(segmentAction: Selector) {
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let segmentedView = UISegmentedControl(items: ["Usage", "Energy Points", "Carbon"])
        segmentedView.selectedSegmentIndex = 0
        segmentedView.layer.cornerRadius = 5.0
        segmentedView.tintColor = UIColor.white
        
        let containerView = UIView()
        containerView.addSubview(segmentedView)
        
        navigationItem.centerViews = [containerView]
        
        //Centers the segmented control in the view
        let segmentedX = (containerView.bounds.width - segmentedView.bounds.width)/2
        let segmentedY = (containerView.bounds.height - segmentedView.bounds.height)/2
        segmentedView.frame.origin = CGPoint(x: segmentedX, y: segmentedY)
        
        segmentedView.addTarget(self, action: segmentAction, for: .valueChanged)
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
        
        self.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
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
            self.leftAxis.axisMaximum = 10 * ceil(max / 10.0)
        }
        
        self.leftAxis.axisMinimum = 0
        
        //Adds some padding
        self.extraTopOffset = 10
        self.extraBottomOffset = -10
        
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
