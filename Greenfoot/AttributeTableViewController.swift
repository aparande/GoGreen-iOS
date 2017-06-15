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
}

class AttributeTableViewController: UITableViewController, DataUpdater {
    var data: GreenData
    var dataKeys:[String]
    var months:[Date]

    override func viewDidLoad() {
        super.viewDidLoad()

        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let attrNib = UINib(nibName: "AttributeCell", bundle: nil)
        tableView.register(attrNib, forCellReuseIdentifier: "AttributeCell")
        
        let editNib = UINib(nibName: "EditDataCell", bundle: nil)
        tableView.register(editNib, forCellReuseIdentifier: "EditCell")
        
        
        navigationItem.backButton.tintColor = UIColor.white
        
        let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
        editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        navigationItem.rightViews = [editButton]
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func beginEdit() {
        self.tableView.setEditing(true, animated: true)
        
        let doneButton = IconButton(image: Icon.check, tintColor: UIColor.white)
        doneButton.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        navigationItem.rightViews = [doneButton]
    }
    
    func endEdit() {
        self.tableView.setEditing(false, animated: true)
        let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
        editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        navigationItem.rightViews = [editButton]
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
        
        self.months = []
        for key in data.getGraphData().keys {
            self.months.append(key)
        }
        
        self.months.sort(by: { (date1, date2) -> Bool in
            return date1.compare(date2) == ComparisonResult.orderedAscending })
        
        
        super.init(style: .grouped)
    }
    
    func updateAttribute(key: String, value: Int) {
        if let _ = data.data[key] {
            data.data[key] = value
        } else {
            data.bonusDict[key] = value
        }
    }
    
    func updateData(month: String, point: Double, path: IndexPath?) {
        let date = Date.monthFormat(date: month)
        self.data.editDataPoint(month: date, y:point)
        
        CoreDataHelper.update(data: data, month: date, updatedValue: point, uploaded: false)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        
        return (data.dataName == "Emissions") ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dataKeys.count
        } else {
            return months.count
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
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
                return cell
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeTableViewCell
                cell.owner = self
                
                if let _ = data.data[key] {
                    cell.setInfo(attribute: key, data: data.data[key]!)
                } else {
                    cell.setInfo(attribute: key, data: data.bonusDict[key]!)
                }
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditCell", for: indexPath) as! EditTableViewCell
            cell.owner = self
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            let month = months[indexPath.row]
            
            cell.setInfo(attribute: formatter.string(from: month), data: data.getGraphData()[month]!)
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && dataKeys.count == 0 {
            return nil
        } else if section == 0 {
            return "Attributes"
        } else {
            return "Data"
        }
    }
    
    //The following deal with editing the table view
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return (indexPath.section == 0) ? UITableViewCellEditingStyle.none : UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertView = UIAlertController(title: "Are You Sure?", message: "Are you sure you would like to delete this data point?", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
                _ in
                let key = self.months.remove(at: indexPath.row)
                self.data.removeDataPoint(month: key)
                CoreDataHelper.delete(data: self.data, month: key)
                self.tableView.deleteRows(at: [indexPath], with: .right)
            }))
            
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            
        }
    }
}
