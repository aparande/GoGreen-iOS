//
//  UtilitiesTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import BLTNBoard
import Material

class UtilitiesTableViewController: SourceAggregatorViewController, UtilityTableViewCellDelegate {
    typealias SourceCategory = CarbonSource.SourceCategory
    
    var navTitle: String
    var sourceCategory: SourceCategory = .utility
    var tableView: UITableView!
    
    init(withTitle title:String, forCategory category: SourceCategory, aggregator: SourceAggregator) {
        self.navTitle = title
        self.sourceCategory = category
        super.init(nibName: nil, bundle: nil)
        
        self.aggregator = aggregator
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.navTitle = ""
        #warning("This is a terrible default")
        self.sourceCategory = .direct
       
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
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        self.prepNavigationBar(titled: navTitle)
                
        let addButton = IconButton(image: Icon.cm.add, tintColor: .white)
        addButton.addTarget(self, action: #selector(showAddSourceBLTNItem), for: .touchUpInside)
        self.navigationItem.rightViews = [addButton]
        
        let fabButton = FABButton(image: Icon.cm.add, tintColor: .white)
        fabButton.addTarget(self, action: #selector(showAddSourceBLTNItem), for: .touchUpInside)
        fabButton.backgroundColor = Colors.green
        
        let menu = FABMenu()
        menu.fabButton = fabButton
        
        self.view.addSubview(menu)
        
        self.view.layout(menu).size(CGSize(width: 40, height: 40)).bottomTrailingSafe(bottom: 70, trailing: 20)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
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
        let rootItem: AddSourceBLTNItem = AddSourceBLTNItem(title: "Add Source", withSourceCategory: self.sourceCategory)
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
