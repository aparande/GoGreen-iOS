//
//  UtilitiesTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import BLTNBoard

class UtilitiesTableViewController: SourceAggregatorViewController, UtilityTableViewCellDelegate {
    var navTitle: String
    var tableView: UITableView!
    
    private var bltnManager: BLTNItemManager?
    
    init(withTitle title:String, aggregator: SourceAggregator) {
        self.navTitle = title
        super.init(nibName: nil, bundle: nil)
        
        self.aggregator = aggregator
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.navTitle = ""
       
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorStyle = .none
        
        let utilityNib = UINib(nibName: "UtilityCell", bundle: nil)
        tableView.register(utilityNib, forCellReuseIdentifier: "UtilityCell")
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        self.title = navTitle
        
        self.prepNavigationBar(titled: navTitle)
    }
    
    func showBulletin(for source: CarbonSource?) {
        guard let source = source else { return }
        
        let rootItem: AddDataBLTNItem = AddDataBLTNItem(title: "Add Data", source: source)
        rootItem.delegate = self
        self.bltnManager = BLTNItemManager(rootItem: rootItem)
        self.bltnManager?.showBulletin(above: self)
    }
    
    func onBLTNPageItemActionClicked(with source: CarbonSource) {
        self.bltnManager?.dismissBulletin(animated: true)
        self.bltnManager = nil
        
        self.navigationController?.pushViewController(GraphViewController.instantiate(for: source), animated: true)
    }
    
    func viewGraph(for source: CarbonSource?) {
        guard let source = source else { return }
        self.navigationController?.pushViewController(GraphViewController.instantiate(for: source), animated: true)
    }
    
    func listData(for source: CarbonSource?) {
        /*
        guard let data = data else { return }
        self.navigationController?.pushViewController(BulkDataViewController(withData: data), animated: true)*/
    }
    
    override func loadView() {
        self.tableView = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.view = tableView
    }
}

extension UtilitiesTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UtilityCell", for: indexPath) as! UtilityTableViewCell
        
        /*
        cell.data = data[indexPath.row]
        cell.owner = self */
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 235
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return aggregator.sources.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
