//
//  UtilitiesTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/23/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit

class UtilitiesTableViewController: UITableViewController {
    
    var data: [GreenData]
    var navTitle: String
    
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UtilityCell", for: indexPath) as! UtilityTableViewCell
        
        let dataType = data[indexPath.row]
        cell.title = dataType.dataName
        cell.lastRecorded = dataType.graphData.last?.month
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
