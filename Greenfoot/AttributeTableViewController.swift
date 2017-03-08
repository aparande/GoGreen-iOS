//
//  AttributeTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class AttributeTableViewController: UITableViewController {
    var data: GreenData
    var dataKeys:[String]

    override func viewDidLoad() {
        super.viewDidLoad()

        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        let nib = UINib(nibName: "AttributeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "AttributeCell")
    }
    
    init(data:GreenData) {
        self.data = data
        self.dataKeys = []
        
        for (key, value) in data.data {
            self.dataKeys.append(key)
        }
        
        
        super.init(style: .plain)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell", for: indexPath) as! AttributeTableViewCell

        let key = dataKeys[indexPath.row]
        cell.setInfo(attribute: key, data: data.data[key]!)

        return cell
    }
}
