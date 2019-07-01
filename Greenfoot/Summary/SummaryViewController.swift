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
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var containerAnchoredTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerFloatingConstraint: NSLayoutConstraint!
    
    private var tableViewExpanded: Bool = false {
        didSet {
            self.tableView.isScrollEnabled = false
            let onComplete: ((Bool) -> Void) = {(finished) in if finished { self.tableView.isScrollEnabled = true}}
            
            if tableViewExpanded {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [], animations: {
                    self.containerFloatingConstraint.isActive = false
                    self.containerAnchoredTopConstraint.isActive = true
                    self.view.layoutIfNeeded()
                }, completion: onComplete)
            } else {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [], animations: {
                    self.containerAnchoredTopConstraint.isActive = false
                    self.containerFloatingConstraint.isActive = true
                    self.view.layoutIfNeeded()
                }, completion: onComplete)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let graphNib = UINib(nibName: "BarGraphCell", bundle: nil)
        tableView.register(graphNib, forCellReuseIdentifier: "GraphCell")
        
        let logNib = UINib(nibName: "LogCell", bundle: nil)
        tableView.register(logNib, forCellReuseIdentifier: "LogCell")
        
        setupTableContainer()
        setupTableView()
    }
    

    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 {
            return
        }
        
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView.superview)
        if translation.y > 0 && tableViewExpanded {
            print("Swiping Down")
            self.tableViewExpanded = false
        } else if translation.y < 0 && !tableViewExpanded {
            print("Swiping Up")
            self.tableViewExpanded = true
        }
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
            navigationItem.titleLabel.font = UIFont.header
        }
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        navigationItem.backButton.tintColor = UIColor.white
    }
}
