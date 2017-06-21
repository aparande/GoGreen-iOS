//
//  GraphViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 2/4/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import Charts

class GraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {

    let greenModal = GreenfootModal.sharedInstance
    var data: GreenData!
    var fabMenu:FABMenu!
    
    @IBOutlet var graph: BarGraph!
    @IBOutlet var attributeTableView: UITableView!
    @IBOutlet var energyPointsLabel: UILabel!
    @IBOutlet var dailyAverageLabel:UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepToolbar()
        
        var infoImage = Icon.info_white
        infoImage = infoImage!.resize(toHeight: 20)
        infoImage = infoImage!.resize(toWidth: 20)
        let infoButton = IconButton(image: infoImage)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        infoButton.imageView?.contentMode = .scaleAspectFit
        navigationItem.rightViews = [infoButton]
        
        graph.loadData(data.getGraphData(), labeled: data.yLabel)
        
        iconImageView.image = data.icon
        
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        dailyAverageLabel.text  = "\(data.averageValue) " + data.averageLabel
        
        attributeTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        createFABMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        attributeTableView.reloadData()
        
        graph.loadData(data.getGraphData(), labeled: data.yLabel)
    }
    
    func setDataType(data:GreenData) {
        //assertionFailure("You need to override this method. Something like data=GreenfootModal.electricData should be put here")
        self.data = data
    }

    func createFABMenu() {
        fabMenu = FABMenu()
        
        let fabButton = FABButton(image: Icon.cm.moreVertical, tintColor: .white)
        fabButton.backgroundColor = Colors.green
        
        let addFabItem = FABMenuItem()
        addFabItem.title = "Add"
        addFabItem.fabButton.image = Icon.cm.add
        addFabItem.fabButton.tintColor = .white
        addFabItem.fabButton.backgroundColor = Colors.green
        addFabItem.fabButton.addTarget(self, action: #selector(bulkAdd), for: .touchUpInside)
        
        let attributeFabItem = FABMenuItem()
        attributeFabItem.title = "Edit"
        attributeFabItem.fabButton.image = Icon.cm.edit
        attributeFabItem.fabButton.tintColor = .white
        attributeFabItem.fabButton.backgroundColor = Colors.green
        attributeFabItem.fabButton.addTarget(self, action: #selector(attributeAdd), for: .touchUpInside)
        
        let shareFabItem = FABMenuItem()
        shareFabItem.title = "Share"
        shareFabItem.fabButton.image = Icon.cm.share
        shareFabItem.fabButton.tintColor = .white
        shareFabItem.fabButton.backgroundColor = Colors.green
        shareFabItem.fabButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [addFabItem, attributeFabItem, shareFabItem]
        
        self.view.layout(fabMenu).size(CGSize(width: 50, height: 50)).bottom(75).right(25)
    }
    
    func bulkAdd() {
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        
        if data.dataName == "Emissions" {
            let aevc = AddEmissionsViewController(style: .grouped)
            navigationController?.pushViewController(aevc, animated: true)
        } else {
            let bvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BulkDataViewController") as! BulkDataViewController
            bvc.setDataType(dataObj: data)
            navigationController?.pushViewController(bvc, animated: true)
        }
    }
    
    func attributeAdd() {
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        let advc = AttributeTableViewController(data: data)
        navigationController?.pushViewController(advc, animated: true)
    }
    
    func share() {
        let message = "I earned "+energyPointsLabel.text!+" Energy Points on Greenfoot from "+data.dataName+"! How many do you have?"
        let activityView = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        activityView.excludedActivityTypes = [.addToReadingList, .airDrop, .assignToContact, .copyToPasteboard, .openInIBooks, .postToFlickr, .postToVimeo, .print, .saveToCameraRoll]
        self.present(activityView, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell")
        
        if cell != nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "AttributeCell")
        }
        
        if indexPath.row < data.data.keys.count {
            let key = Array(data.data.keys)[indexPath.row]
            cell!.textLabel?.text = key
            cell!.detailTextLabel?.text = "\(data.data[key]!)"
        } else {
            let key = Array(data.bonusDict.keys)[indexPath.row-data.data.keys.count]
            cell!.textLabel?.text = key
            cell!.detailTextLabel?.text = "\(data.bonusDict[key]!)"
        }
        
        cell!.textLabel?.font = UIFont(name: "GeosansLight", size: 18)
        cell!.detailTextLabel?.font = UIFont(name: "GeosansLight", size: 18)
        
        cell!.textLabel?.textColor = UIColor(red: 47/255, green: 204/255, blue: 113/255, alpha: 1)
        cell!.detailTextLabel?.textColor = UIColor(red: 47/255, green: 204/255, blue: 113/255, alpha: 1)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.data.keys.count + data.bonusDict.keys.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }
    
    func showInfo() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let dcvc = storyboard.instantiateViewController(withIdentifier: "DescriptionCollectionViewController") as! DescriptionCollectionViewController
        dcvc.setData(data: self.data)
        navigationController?.pushViewController(dcvc, animated: true)
    }
}
