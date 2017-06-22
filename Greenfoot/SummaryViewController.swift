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
    
    func prepSegmentedToolbar(segmentAction: Selector) {
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let segmentedView = UISegmentedControl(items: ["Usage", "Energy Points"])
        segmentedView.selectedSegmentIndex = 0
        segmentedView.layer.cornerRadius = 5.0
        segmentedView.tintColor = UIColor.white
        
        let containerView = UIView()
        containerView.addSubview(segmentedView)
        
        navigationItem.centerViews = [containerView]
        
        //Centers the segmented control in the view
        let segmentedX = (containerView.bounds.width - segmentedView.bounds.width*1.5)/2
        let segmentedY = (containerView.bounds.height - segmentedView.bounds.height)/2
        segmentedView.frame.origin = CGPoint(x: segmentedX, y: segmentedY)
        
        segmentedView.addTarget(self, action: segmentAction, for: .valueChanged)
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

