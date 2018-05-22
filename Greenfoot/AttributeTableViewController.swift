//
//  AttributeTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class AttributeTableViewController: UITableViewController, DataUpdater {
    var data: GreenData
    var dataKeys:[String]
    
    var expandedRows = Set<Int>()
    
    var keyToExpand:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepNavigationBar(titled: "Attributes")
        
        let attrNib = UINib(nibName: "AttributeCell", bundle: nil)
        tableView.register(attrNib, forCellReuseIdentifier: "AttributeCell")
        
        let descNib = UINib(nibName: "AttributeDescriptionCell", bundle: nil)
        tableView.register(descNib, forCellReuseIdentifier: "AttributeDescription")
        
        //Table View Header/Footer Setup
        if (UIDevice.current.userInterfaceIdiom == .pad) {
            self.tableView.tableHeaderView = createHeader()
        } else {
            self.tableView.tableHeaderView = UIView(frame: CGRect.zero)
        }
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        //Table View Function Customization
        self.tableView.isScrollEnabled = false
        self.tableView.allowsMultipleSelection = true
        
        
        //Table View Looks Customization
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
        self.tableView.cellLayoutMarginsFollowReadableWidth = false
        self.tableView.showsHorizontalScrollIndicator = false
        self.tableView.showsVerticalScrollIndicator = false
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
        var type = "Data"
        if let _ = data.data[key] {
            data.data[key] = GreenAttribute(value: value, lastUpdated: Date())
        } else {
            type = "Bonus"
            data.bonusDict[key] = GreenAttribute(value: value, lastUpdated: Date())
        }
        
        var parameters:[String:Any] = ["month":"NA", "amount":value, "lastUpdated": Date().timeIntervalSince1970]
        parameters["dataType"] = [self.data.dataName, type, key].joined(separator: ":")
        let id=[APIRequestType.log.rawValue, self.data.dataName, key].joined(separator: ":")
        data.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
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
            cell.detailTextLabel?.text = String(describing: data.data[key]!.value)
            
            cell.selectionStyle = .none
            
            return cell
            
        } else {
            if self.expandedRows.contains(indexPath.row-1) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeDescription", for: indexPath) as! AttributeDescriptionTableViewCell
                cell.descriptionLabel.text = dataKeys[indexPath.row]
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeTableViewCell
            cell.owner = self
            
            if let _ = data.data[key] {
                cell.setInfo(attribute: key, data: data.data[key]!.value)
            } else {
                cell.setInfo(attribute: key, data: data.bonusDict[key]!.value)
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.beginUpdates()
        
        let key = dataKeys[indexPath.row]
        
        switch self.expandedRows.contains(indexPath.row) {
        case true:
            dataKeys.remove(at: indexPath.row + 1)
            self.expandedRows.remove(indexPath.row)
            let oldPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            self.tableView.deleteRows(at: [oldPath], with: .top)
        case false:
            dataKeys.insert(data.descriptions[key]!, at: indexPath.row + 1)
            self.expandedRows.insert(indexPath.row)
            let newPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
            self.tableView.insertRows(at: [newPath], with: .top)
        }
        
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.tableView.beginUpdates()
        
        dataKeys.remove(at: indexPath.row + 1)
        self.expandedRows.remove(indexPath.row)
        let oldPath = IndexPath(row: indexPath.row+1, section: indexPath.section)
        self.tableView.deleteRows(at: [oldPath], with: .top)
        
        self.tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.expandedRows.contains(indexPath.row-1) {
            return 160
        } else {
            return 40
        }
    }
    
    private func createHeader() -> NavigationBar {
        let navBar = NavigationBar(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.bounds.width, height: 75)))
        
        navBar.tintColor = UIColor.white
        navBar.barTintColor = Colors.green
        
        let closeButton = IconButton.init(image: Icon.close, tintColor: .white)
        closeButton.addTarget(self, action: #selector(closeForm), for: .touchUpInside)
        
        let navigationItem = UINavigationItem(title: "Attributes")
        navigationItem.titleLabel.text = "Attributes"
        navigationItem.titleLabel.textColor = UIColor.white
        navigationItem.titleLabel.font = UIFont(name: "DroidSans", size: 20)
        
        navigationItem.leftViews = [closeButton]
        
        navBar.setItems([navigationItem], animated: false)
        
        return navBar
    }
    
    @objc private func closeForm() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

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
