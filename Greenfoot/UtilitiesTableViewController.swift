//
//  UtilitiesTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import BLTNBoard

class UtilitiesTableViewController: UITableViewController, UtilityTableViewCellDelegate {
    var data: [GreenData]
    var navTitle: String
    
    private var bltnManager: BLTNItemManager?
    
    init(withTitle title:String, forGreenData greenData:[GreenData]) {
        self.navTitle = title
        self.data = greenData
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.navTitle = ""
        self.data = []
        
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
    
    func showBulletin(for data: GreenData?) {
        guard let data = data else { return }
        
        let rootItem: AddDataBLTNItem = AddDataBLTNItem(title: "Add Data", data: data)
        rootItem.delegate = self
        self.bltnManager = BLTNItemManager(rootItem: rootItem)
        self.bltnManager?.showBulletin(above: self)
    }
    
    func onBLTNPageItemActionClicked(with data: GreenData) {
        self.bltnManager?.dismissBulletin(animated: true)
        self.bltnManager = nil
        
        self.navigationController?.pushViewController(GraphViewController.instantiate(for: data), animated: true)
    }
    
    func viewGraph(for data: GreenData?) {
        guard let data = data else { return }
        self.navigationController?.pushViewController(GraphViewController.instantiate(for: data), animated: true)
    }
    
    func listData(for data: GreenData?) {
        guard let data = data else { return }
        self.navigationController?.pushViewController(BulkDataViewController(withData: data), animated: true)
    }
    

}

extension UtilitiesTableViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UtilityCell", for: indexPath) as! UtilityTableViewCell
        
        cell.data = data[indexPath.row]
        cell.owner = self
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 235
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
