//
//  GraphViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 2/4/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import ScrollableGraphView
import Material

class GraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {

    let greenModal = GreenfootModal.sharedInstance
    var data: GreenData!
    var fabMenu:FABMenu!
    
    @IBOutlet var graph: ScrollableGraphView!
    @IBOutlet var attributeTableView: UITableView!
    @IBOutlet var energyPointsLabel: UILabel!
    @IBOutlet var dailyAverageLabel:UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepToolbar()
        
        var infoImage = Icon.info_white
        infoImage = infoImage!.resize(toHeight: 30)
        infoImage = infoImage!.resize(toWidth: 30)
        let infoButton = IconButton(image: infoImage)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        infoButton.imageView?.contentMode = .scaleAspectFit
        navigationItem.rightViews = [infoButton]
        
        customizeGraph()
        
        iconImageView.image = data.icon
        
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        dailyAverageLabel.text  = "\(data.averageValue) " + data.averageLabel
        
        createFABMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        attributeTableView.reloadData()
        customizeGraph()
    }
    
    func setDataType(data:GreenData) {
        //assertionFailure("You need to override this method. Something like data=GreenfootModal.electricData should be put here")
        self.data = data
    }
    
    func customizeGraph() {
        //Customize the graph stuff here, and set the data
        if let _ =  graph {
            var dates:[Date] = Array(data.getGraphData().keys)
            dates.sort(by: { (date1, date2) -> Bool in
                return date1.compare(date2) == ComparisonResult.orderedAscending })
            
            var labels: [String] = []
            var points: [Double] = []
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            
            for date in dates {
                points.append(data.getGraphData()[date]!)
                labels.append(formatter.string(from: date))
            }
            graph.set(data: points, withLabels: labels)
            
            graph.referenceLineUnits = data.yLabel
        }
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
        attributeFabItem.title = "Attributes"
        attributeFabItem.fabButton.image = Icon.cm.edit
        attributeFabItem.fabButton.tintColor = .white
        attributeFabItem.fabButton.backgroundColor = Colors.green
        attributeFabItem.fabButton.addTarget(self, action: #selector(attributeAdd), for: .touchUpInside)
        
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [addFabItem, attributeFabItem]
        
        
        self.view.layout(fabMenu).size(CGSize(width: 50, height: 50)).bottom(24).right(24)
    }
    
    func bulkAdd() {
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        
        if data.dataName == "Emissions" && data.data["Average MPG"] == 0 {
            let alertView = UIAlertController(title: "Error", message: "Before you can input your mileage data, please enter the number of cars you have and their average miles per gallon", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            return
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
