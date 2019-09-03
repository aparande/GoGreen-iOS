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

class SummaryViewController: SourceAggregatorViewController {
    @IBOutlet weak var tableContainerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emblemView: CircularEmblemView!
    @IBOutlet weak var lastMonthLabel: UILabel!
    @IBOutlet weak var usAverageLabel: UILabel!
    
    @IBOutlet weak var containerAnchoredTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerFloatingConstraint: NSLayoutConstraint!
    
    var sections: [TableViewSection] = []
    
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
        setupTableViewSections()
    }
    
    override func refresh() {
        super.refresh()
        setupTableViewSections()
        self.tableView.reloadData()
        
        emblemView.value = String(aggregator.sumCarbon())
        lastMonthLabel.text = String(aggregator.carbonEmitted(on: Date().lastMonth))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let source = sender as? CarbonSource, let destination = segue.destination as? GraphViewController {
            destination.dataSource = source
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
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barStyle = .default
        
        if let text = title {
            self.title = text
            self.navigationItem.titleLabel.text = text
            self.navigationItem.titleLabel.textColor = UIColor.white
            self.navigationItem.titleLabel.font = UIFont.navigationTitle
        }
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.barTintColor = Colors.green
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
}
