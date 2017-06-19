//
//  ViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import ScrollableGraphView

class SummaryViewController: UIViewController {
    
    @IBOutlet weak var pointLabel:UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var graph: ScrollableGraphView!
    
    private var monthlyEP:[Date: Double] = [:]
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
        self.scrollView.contentSize = CGSize(width: viewFrame.width * 2, height: viewHeight)
        
        let subViews = UINib.init(nibName: "SummaryView", bundle: nil).instantiate(withOwner: self, options: nil) as! [UIView]
        
        subViews[0].frame = viewFrame!
        subViews[0].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showGraph)))
        self.scrollView.addSubview(subViews[0])
        
        let newOrigin = CGPoint(x:viewFrame!.width, y:0)
        subViews[1].frame = CGRect(origin: newOrigin, size: viewFrame!.size)
        subViews[1].addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showEmblem)))
        self.scrollView.addSubview(subViews[1])
        
        //Makes sure the scrollview fits the screen and doesn't allow vertical scrolling
        self.automaticallyAdjustsScrollViewInsets = false
        
        let modal = GreenfootModal.sharedInstance
        pointLabel.text = "\(modal.totalEnergyPoints)"
        
        for (_, data) in modal.data {
            for (month, value) in data.getEPData() {
                if let ep = monthlyEP[month] {
                    monthlyEP[month] = ep + Double(value)
                } else {
                    monthlyEP[month] = Double(value)
                }
            }
        }
        
        graph.design()
        graph.loadData(monthlyEP, labeled: "EP")
    }
    
    func showGraph() {
        let newOrigin = CGPoint(x: self.viewFrame!.width, y:0)
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
    
    private func loadGraph() {
        //Customize the graph stuff here, and set the data
        if let _ =  graph {
            
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
}

extension ScrollableGraphView {
    func design() {
        self.backgroundColor = Colors.green
        self.backgroundFillColor = Colors.green
        self.lineColor = UIColor.clear
        
        self.shouldDrawBarLayer = true
        self.barColor = UIColor.white.withAlphaComponent(0.5)
        self.shouldDrawDataPoint = false
        self.barLineColor = UIColor.clear
        
        self.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        self.referenceLineColor = UIColor.white.withAlphaComponent(0.5)
        self.referenceLineLabelColor = UIColor.white
        self.dataPointLabelColor = UIColor.white.withAlphaComponent(0.8)
        
        self.leftmostPointPadding = 75
        self.topMargin = 20
        
        self.shouldAutomaticallyDetectRange = true
        self.shouldRangeAlwaysStartAtZero = false
        self.clipsToBounds = true
        self.direction = .leftToRight
        
        self.cornerRadius = 10
    }
    
    func loadData(_ data:[Date: Double], labeled label:String) {
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
        
        if !hasNegative {
            self.shouldRangeAlwaysStartAtZero = true
        }
        
        self.set(data: points, withLabels: labels)
        
        self.referenceLineUnits = label
        
        self.layoutSubviews()
        
        if self.contentSize.width > self.frame.width {
            self.setContentOffset(CGPoint(x:self.contentSize.width - self.frame.width+30, y:0), animated: true)
        }
    }
}

