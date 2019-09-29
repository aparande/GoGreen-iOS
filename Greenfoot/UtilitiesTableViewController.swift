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
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddSourceBLTNItem))
        self.navigationItem.setRightBarButton(addButton, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tableView.reloadData()
    }

    func showBulletin(for source: CarbonSource?) {
        guard let source = source else { return }
        
        self.presentBulletin(forSource: source)
    }
    
    override func onBLTNPageItemActionClicked(with source: CarbonSource) {
        self.aggregator.addSource(source)
        super.onBLTNPageItemActionClicked(with: source)
        viewGraph(for: source)
    }
    
    func viewGraph(for source: CarbonSource?) {
        guard let source = source else { return }
        self.navigationController?.pushViewController(GraphViewController.instantiate(for: source), animated: true)
    }
    
    func listData(for source: CarbonSource?) {
        guard let source = source else { return }
        self.navigationController?.pushViewController(BulkDataViewController(withSource: source), animated: true)
    }
    
    override func loadView() {
        self.tableView = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.view = tableView
    }
    
    @objc func showAddSourceBLTNItem() {
        let rootItem: AddSourceBLTNItem = AddSourceBLTNItem(title: "Add Source", withSourceCategory: .travel)
        rootItem.delegate = self
        bulletinManager = BLTNItemManager(rootItem: rootItem)
        bulletinManager?.showBulletin(above: self)
    }
}

extension UtilitiesTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UtilityCell", for: indexPath) as! UtilityTableViewCell
        
        
        cell.source = self.aggregator.sources[indexPath.row]
        cell.owner = self
        
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
