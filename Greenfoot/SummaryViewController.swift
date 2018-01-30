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
import UserNotifications

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
        
        let infoButton = IconButton(image: Icon.info_white.resize(toWidth: 20)!.resize(toHeight: 20)!, tintColor: UIColor.white)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        navigationItem.leftViews = [infoButton]
        
        let rankings = GreenfootModal.sharedInstance.rankings
        if rankings.keys.count != 4 {
            rankingView.isHidden = true
        } else {
            cityRankLabel.text = "\(rankings["CityRank"]!)"
            cityCountLabel.text = "out of \(rankings["CityCount"]!)"
            stateRankLabel.text = "\(rankings["StateRank"]!)"
            stateCountLabel.text = "out of \(rankings["StateCount"]!)"
            
            /*
             cityRankLabel.text = "8945"
             cityCountLabel.text = "out of 26,328"
             stateRankLabel.text = "1,786,554"
             stateCountLabel.text = "out of 12,800,000"*/
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRank), name: NSNotification.Name(rawValue: APINotifications.stateRank.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRank), name: NSNotification.Name(rawValue: APINotifications.cityRank.rawValue), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pointLabel.text = "\(GreenfootModal.sharedInstance.totalEnergyPoints)"
        
        GreenfootModal.sharedInstance.logEnergyPoints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SettingsManager.sharedInstance.requestNotificationPermissions(completion: nil)
    }
    
    @objc func share() {
        let message = "I earned "+pointLabel.text!+" Energy Points on Greenfoot! How many do you have?"
        let activityView = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityView.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .openInIBooks, .postToFlickr, .postToVimeo, .print, .saveToCameraRoll]
        self.present(activityView, animated: true, completion: nil)
    }
    
    @objc func refreshRank() {
        let rankings = GreenfootModal.sharedInstance.rankings
        if rankings.keys.count != 4 {
            rankingView.isHidden = true
        } else {
            cityRankLabel.text = "\(rankings["CityRank"]!)"
            cityCountLabel.text = "out of \(rankings["CityCount"]!)"
            stateRankLabel.text = "\(rankings["StateRank"]!)"
            stateCountLabel.text = "out of \(rankings["StateCount"]!)"
            
            /*
            cityRankLabel.text = "8945"
            cityCountLabel.text = "out of 26,328"
            stateRankLabel.text = "1,786,554"
            stateCountLabel.text = "out of 12,800,000"*/
            
            rankingView.isHidden = false
        }
    }
    @IBAction func showHistory(_ sender: Any) {
        let hvc = HistoryViewController()
        self.navigationController?.pushViewController(hvc, animated: true)
    }
    
    @objc func showInfo() {
        let svc = SettingsTableViewController()
        self.navigationController?.pushViewController(svc, animated: true)
    }
}

extension UIViewController {
    func prepToolbar() {
        let logo = UIImageView(image: Icon.logo_white)
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.barTintColor = Colors.green
    }
    
    func prepSegmentedToolbar(segmentAction: Selector) {
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let segmentedView = UISegmentedControl(items: ["Usage", "Energy Points", "Carbon"])
        segmentedView.selectedSegmentIndex = 0
        segmentedView.layer.cornerRadius = 5.0
        segmentedView.tintColor = UIColor.white
        
        navigationItem.centerViews = [segmentedView]
        
        segmentedView.addTarget(self, action: segmentAction, for: .valueChanged)
    }
    
    func prepNavigationBar(titled title:String?) {
        if let text = title {
            navigationItem.titleLabel.text = text
            navigationItem.titleLabel.textColor = UIColor.white
            navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 17)
        }
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        navigationItem.backButton.tintColor = UIColor.white
    }
}
