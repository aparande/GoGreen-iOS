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

class SummaryViewController: UIViewController {
    
    @IBOutlet weak var pointLabel:UILabel!
    
    @IBOutlet weak var cityRankLabel: UILabel!
    @IBOutlet weak var cityCountLabel: UILabel!
    
    @IBOutlet weak var stateRankLabel: UILabel!
    @IBOutlet weak var stateCountLabel: UILabel!
    
    @IBOutlet weak var rankingView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepToolbar()
        
        let shareButton = IconButton(image: Icon.cm.share, tintColor: UIColor.white)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        navigationItem.rightViews = [shareButton]
        
        let rankings = GreenfootModal.sharedInstance.rankings
        if rankings.keys.count != 4 {
            rankingView.isHidden = true
        } else {
            cityRankLabel.text = "\(rankings["CityRank"]!)"
            cityCountLabel.text = "out of \(rankings["CityCount"]!)"
            stateRankLabel.text = "\(rankings["StateRank"]!)"
            stateCountLabel.text = "out of \(rankings["StateCount"]!)"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRank), name: NSNotification.Name(rawValue: APINotifications.stateRank.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRank), name: NSNotification.Name(rawValue: APINotifications.cityRank.rawValue), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        pointLabel.text = "\(GreenfootModal.sharedInstance.totalEnergyPoints)"
        GreenfootModal.sharedInstance.logEnergyPoints(refreshRankings: false)
    }
    
    func share() {
        let message = "I earned "+pointLabel.text!+" Energy Points on Greenfoot! How many do you have?"
        let activityView = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityView.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .openInIBooks, .postToFlickr, .postToVimeo, .print, .saveToCameraRoll]
        self.present(activityView, animated: true, completion: nil)
    }
    
    func refreshRank() {
        let rankings = GreenfootModal.sharedInstance.rankings
        if rankings.keys.count != 4 {
            rankingView.isHidden = true
        } else {
            cityRankLabel.text = "\(rankings["CityRank"]!)"
            cityCountLabel.text = "out of \(rankings["CityCount"]!)"
            stateRankLabel.text = "\(rankings["StateRank"]!)"
            stateCountLabel.text = "out of \(rankings["StateCount"]!)"
            
            rankingView.isHidden = false
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
