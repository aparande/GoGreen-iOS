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
    
    var graph: ScrollableGraphView?
    private var monthlyEP:[Date: Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        prepToolbar()
        
        let shareButton = IconButton(image: Icon.cm.share, tintColor: UIColor.white)
        shareButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        navigationItem.rightViews = [shareButton]
        
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
    }
    
    func share() {
        let message = "I earned "+pointLabel.text!+" Energy Points on Greenfoot! How many do you have?"
        let activityView = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityView.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .openInIBooks, .postToFlickr, .postToVimeo, .print, .saveToCameraRoll]
        self.present(activityView, animated: true, completion: nil)
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
        graph.shouldRangeAlwaysStartAtZero = true
        graph.shouldAdaptRange = true
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

