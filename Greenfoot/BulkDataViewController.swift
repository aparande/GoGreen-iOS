//
//  BulkDataViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/1/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class BulkDataViewController: UITableViewController {
    var source: CarbonSource!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let historyNib = UINib(nibName: "HistoryCell", bundle: nil)
        tableView.register(historyNib, forCellReuseIdentifier: "HistoryCell")
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        self.title = source.name
        
        navigationItem.backButton.titleLabel?.font = UIFont.button
        navigationItem.backButton.titleColor = UIColor.white
        navigationItem.backButton.tintColor = UIColor.white
        
        if self == self.navigationController?.viewControllers[0] {
            let backButton = IconButton()
            backButton.titleLabel?.font = UIFont.button
            backButton.titleColor = UIColor.white
            backButton.tintColor = UIColor.white
            backButton.addTarget(self, action: #selector(returnToTutorial), for: .touchUpInside)
            navigationItem.leftViews = [backButton]
        }
    }
    
    
    @objc func returnToTutorial() {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func beginEdit() {
        self.tableView.setEditing(true, animated: true)
        
        let doneButton = IconButton(image: Icon.check, tintColor: UIColor.white)
        doneButton.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        navigationItem.rightViews = [doneButton]
    }
    
    @objc func endEdit() {
        self.tableView.setEditing(false, animated: true)
        
        let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
        editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        navigationItem.rightViews = [editButton]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.points.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryTableViewCell
        
        let sectionData = source.points
        //The data is ordered with increasing date, so to see most recent dates first, traverse the array backwards
        let index = sectionData.count - 1 - indexPath.row
        
        cell.point = sectionData[index]
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}
