//
//  DescriptionTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/21/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit

class DescriptionTableViewController: UITableViewController {

    let data: GreenData!
    
    init(data: GreenData) {
        self.data = data
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "AttributeDescriptorCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "AttributeDescriptor")
        tableView.estimatedRowHeight = 105
        
        navigationItem.backButton.tintColor = UIColor.white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.attributes.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeDescriptor") as! DescriptionTableCell
        
        // Configure the cell...
        cell.setInfo(attribute: data.attributes[indexPath.row], description: data.descriptions[indexPath.row])
        
        return cell
    }
}

class DescriptionTableCell: UITableViewCell {
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    func setInfo(attribute:String, description:String) {
        attributeLabel.text = attribute
        descriptionLabel.text = description
    }
}
