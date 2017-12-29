//
//  AttributeTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

protocol DataUpdater {
    func updateAttribute(key:String, value:Int)
    func updateData(month:String, point:Double, path: IndexPath?)
    func updateError()
}

//Provides defaults to effectually make these methods optional
extension DataUpdater {
    func updateAttribute(key:String, value:Int) {
        assertionFailure("Method not implemented")
    }
    
    func updateData(month:String, point:Double, path: IndexPath?) {
        assertionFailure("Method not implemented")
    }
    
    func updateError() {
        assertionFailure("Method not implemented")
    }
}

class AttributeTableViewController: UITableViewController, DataUpdater {
    var data: GreenData
    var dataKeys:[String]
    
    var expandedRows = Set<Int>()
    
    var keyToExpand:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleLabel.text = "Attributes"
        navigationItem.titleLabel.textColor = UIColor.white
        navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 17)
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let attrNib = UINib(nibName: "AttributeCell", bundle: nil)
        tableView.register(attrNib, forCellReuseIdentifier: "AttributeCell")
        
        navigationItem.backButton.tintColor = UIColor.white
        
        self.tableView.tableHeaderView = UIView(frame: CGRect.zero)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
        
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        data.recalculateEP()
    }
    
    init(data:GreenData) {
        self.data = data
        self.dataKeys = []
        
        for key in data.bonusDict.keys {
            self.dataKeys.append(key)
        }
        for key in data.data.keys {
            self.dataKeys.append(key)
        }
        
        super.init(style: .plain)
    }
    
    func updateAttribute(key: String, value: Int) {
        if let _ = data.data[key] {
            data.data[key] = value
        } else {
            data.bonusDict[key] = value
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = dataKeys[indexPath.row]
        
        if key == "Average MPG" || key == "Number of Cars" {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "General Cell")
            
            let geoSans = UIFont(name: "GeosansLight", size: 23.0)
            cell.textLabel?.font = geoSans!
            cell.textLabel?.textColor = Colors.green
            
            let droidSans = UIFont(name: "Droid Sans", size: 15.0)
            cell.detailTextLabel?.font = droidSans
            cell.detailTextLabel?.textColor = UIColor.black
            
            cell.textLabel?.text = key
            cell.detailTextLabel?.text = String(describing: data.data[key]!)
            
            cell.selectionStyle = .none
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeTableViewCell
            cell.owner = self
            
            if let _ = data.data[key] {
                cell.setInfo(attribute: key, data: data.data[key]!, description: data.descriptions[key]!)
            } else {
                cell.setInfo(attribute: key, data: data.bonusDict[key]!, description: data.descriptions[key]!)
            }
            
            cell.isExpanded = self.expandedRows.contains(indexPath.row)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AttributeTableViewCell else {
            return
        }
        
        switch cell.isExpanded {
        case true:
            self.expandedRows.remove(indexPath.row)
        case false:
            self.expandedRows.insert(indexPath.row)
        }
        
        cell.isExpanded = !cell.isExpanded
        
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AttributeTableViewCell else {
            return
        }
        
        self.expandedRows.remove(indexPath.row)
        
        cell.isExpanded = false
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
}
