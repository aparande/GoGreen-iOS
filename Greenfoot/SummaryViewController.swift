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
    
    private var monthlyEP:[Date: Int] = [:]
    private var viewFrame: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepToolbar()
        
        let shareButton = IconButton(image: Icon.cm.share, tintColor: UIColor.white)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        navigationItem.rightViews = [shareButton]
        
        let viewHeight = self.view.frame.height - UIApplication.shared.statusBarFrame.height - (self.navigationController?.navigationBar.frame.height)!
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
        
        let modal = GreenfootModal.sharedInstance
        pointLabel.text = "\(modal.totalEnergyPoints)"
        
        for (_, data) in modal.data {
            for (month, value) in data.getEPData() {
                if let ep = monthlyEP[month] {
                    monthlyEP[month] = ep+value
                } else {
                    monthlyEP[month] = value
                }
            }
        }
        
        designGraph()
        loadGraph()
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
            var dates:[Date] = Array(monthlyEP.keys)
            dates.sort(by: { (date1, date2) -> Bool in
                return date1.compare(date2) == ComparisonResult.orderedAscending })
            
            var labels: [String] = []
            var points: [Double] = []
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            
            var hasNegative = false
            
            for date in dates {
                let point = Double(monthlyEP[date]!)
                
                if !hasNegative {
                    hasNegative = (point < 0)
                }
                
                points.append(point)
                labels.append(formatter.string(from: date))
            }
            
            if !hasNegative {
                graph.shouldRangeAlwaysStartAtZero = true
            }
            
            graph.set(data: points, withLabels: labels)
            
            graph.referenceLineUnits = "EP"
            
            graph.layoutSubviews()
            
            if graph.contentSize.width > graph.frame.width {
                graph.setContentOffset(CGPoint(x:graph.contentSize.width - graph.frame.width+30, y:0), animated: true)
            }
        }
    }
    
    private func designGraph() {
        guard let graph = self.graph else {
            return
        }
        graph.backgroundColor = Colors.green
        graph.backgroundFillColor = Colors.green
        graph.lineColor = UIColor.clear
        
        graph.shouldDrawBarLayer = true
        graph.barColor = UIColor.white.withAlphaComponent(0.5)
        graph.shouldDrawDataPoint = false
        graph.barLineColor = UIColor.clear
        
        graph.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        graph.referenceLineColor = UIColor.white.withAlphaComponent(0.5)
        graph.referenceLineLabelColor = UIColor.white
        graph.dataPointLabelColor = UIColor.white.withAlphaComponent(0.8)
        
        graph.leftmostPointPadding = 75
        graph.topMargin = 20
        
        graph.shouldAutomaticallyDetectRange = true
        graph.shouldRangeAlwaysStartAtZero = false
        graph.clipsToBounds = true
        graph.direction = .leftToRight
        
        graph.cornerRadius = 10
    }
}

extension UIViewController {
    func prepToolbar() {
        let menuButton = IconButton(image: Icon.cm.menu)
        menuButton.addTarget(navigationDrawerController, action: #selector(NavigationDrawerController.openLeftView(velocity:)), for: .touchUpInside)
        navigationItem.leftViews = [menuButton]
        
        let logo = UIImageView(image: Icon.logo_white)
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        menuButton.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
    }
}

