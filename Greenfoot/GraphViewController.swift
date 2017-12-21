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

class GraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, ChartViewDelegate {

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
        prepSegmentedToolbar(segmentAction: #selector(changeGraph(sender:)))
        
        if data.dataName == GreenDataType.water.rawValue {
            let segmentedView = self.navigationItem.centerViews[0] as? UISegmentedControl
            segmentedView?.removeSegment(at: 2, animated: false)
        }
        
        graph.loadData(data.getGraphData(), labeled: data.yLabel)
        graph.delegate = self
        
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
        
        graph.highlightValues(nil)
        
        guard let segmentedView = self.navigationItem.centerViews[0].subviews[0] as? UISegmentedControl else {
            graph.loadData(data.getGraphData(), labeled: data.yLabel)
            return
        }
        changeGraph(sender: segmentedView)
    }
    
    @objc func changeGraph(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.dailyAverageLabel.text = "\(data.averageValue) " + data.averageLabel
            graph.loadData(data.getGraphData(), labeled: data.yLabel)
            break
        case 1:
            var epData:[Date:Double] = [:]
            for (key, value) in data.getEPData() {
                epData[key] = Double(value)
            }
            self.dailyAverageLabel.text = "\(data.averageValue) " + data.averageLabel
            graph.loadData(epData, labeled: "Energy Points")
            break
        case 2:
            self.dailyAverageLabel.text = "\(data.averageCarbon) lbs of Carbon per Day"
            graph.loadData(data.getCarbonData(), labeled: "Pounds of Carbon")
            break
        default:
            break
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        //Create the point viewer and push it onto the navigation stack
        var labels = data.getGraphData().keys.sorted(by: {
            (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedAscending
        })
        
        if Int(entry.x) >= labels.count {
            return
        }
        
        let label = labels[Int(entry.x)]
        let labelString = Date.monthFormat(date: label)
        
        var values:[String: Double] = ["Usage":data.getGraphData()[label]!, "EP":Double(data.getEPData()[label]!)]
        if let value = data.getCarbonData()[label] {
            values["Carbon"] = value
        }
        
        let pointVc = DataPointViewController(unit: data.yLabel, timestamp: labelString, values: values, data: self.data)
        self.navigationController?.pushViewController(pointVc, animated: true)
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
        addFabItem.title = "Add/Edit"
        addFabItem.fabButton.image = Icon.cm.add
        addFabItem.fabButton.tintColor = .white
        addFabItem.fabButton.backgroundColor = Colors.green
        addFabItem.fabButton.addTarget(self, action: #selector(bulkAdd), for: .touchUpInside)
        
        var attributeFabItem:FABMenuItem?
        if data.data.keys.count != 0 || data.bonusDict.keys.count != 0 {
            attributeFabItem = FABMenuItem()
            attributeFabItem!.title = "Attributes"
            attributeFabItem!.fabButton.image = Icon.cm.star
            attributeFabItem!.fabButton.tintColor = .white
            attributeFabItem!.fabButton.backgroundColor = Colors.green
            attributeFabItem!.fabButton.addTarget(self, action: #selector(attributeAdd), for: .touchUpInside)
        }
        
        let shareFabItem = FABMenuItem()
        shareFabItem.title = "Share"
        shareFabItem.fabButton.image = Icon.cm.share
        shareFabItem.fabButton.tintColor = .white
        shareFabItem.fabButton.backgroundColor = Colors.green
        shareFabItem.fabButton.addTarget(self, action: #selector(share), for: .touchUpInside)
        
        fabMenu.fabButton = fabButton
        
        if let attributeButton = attributeFabItem {
            fabMenu.fabMenuItems = [addFabItem, attributeButton, shareFabItem]
        } else {
            fabMenu.fabMenuItems = [addFabItem, shareFabItem]
        }
        
        
        self.view.layout(fabMenu).size(CGSize(width: 50, height: 50)).bottom(75).right(25)
    }
    
    @objc func bulkAdd() {
        fabMenu.close()
        fabMenu.fabButton?.animate(.rotate(0))
        
        if data.dataName == "Driving" {
            let aevc = DrivingDataViewController(withData: data as! DrivingData)
            navigationController?.pushViewController(aevc, animated: true)
        } else {
            let bvc = BulkDataViewController(withData: data)
            navigationController?.pushViewController(bvc, animated: true)
        }
    }
    
    @objc func attributeAdd() {
        fabMenu.close()
        fabMenu.fabButton?.animate(.rotate(0))
        let advc = AttributeTableViewController(data: data)
        navigationController?.pushViewController(advc, animated: true)
    }
    
    @objc func share() {
        let message = "I earned "+energyPointsLabel.text!+" Energy Points on GoGreen from "+data.dataName+"! How many do you have?"
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
}
