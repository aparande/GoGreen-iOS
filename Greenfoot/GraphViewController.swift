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

class GraphViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let greenModal = GreenfootModal.sharedInstance
    var data: GreenData!
    @IBOutlet var graph: ScrollableGraphView!
    @IBOutlet var attributeTableView: UITableView!
    @IBOutlet var energyPointsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let menuButton = IconButton(image: Icon.cm.menu)
        menuButton.addTarget(navigationDrawerController, action: #selector(NavigationDrawerController.openLeftView(velocity:)), for: .touchUpInside)
        navigationItem.leftViews = [menuButton]
        
        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        menuButton.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        setDataType()
        customizeGraph()
        
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        
       createFABMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
    }
    
    func reloadData() {
        energyPointsLabel.text = "\(data.energyPoints) Energy Points"
        customizeGraph()
    }
    
    func setDataType() {
        assertionFailure("You need to override this method. Something like data=GreenfootModal.electricData should be put here")
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
        }
    }
    
    func createFABMenu() {
        assertionFailure("You need to override this method and create the FAB Menu")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: "AttributeCell")
        
        if cell != nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "AttributeCell")
        }
        
        let key = Array(data.data.keys)[indexPath.row]
        cell!.textLabel?.text = key
        cell!.detailTextLabel?.text = "\(data.data[key]!)"
        
        cell!.textLabel?.font = UIFont(name: "GeosansLight", size: 18)
        cell!.detailTextLabel?.font = UIFont(name: "GeosansLight", size: 18)
        
        cell!.textLabel?.textColor = UIColor(red: 47/255, green: 204/255, blue: 113/255, alpha: 1)
        cell!.detailTextLabel?.textColor = UIColor(red: 47/255, green: 204/255, blue: 113/255, alpha: 1)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.data.keys.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }
}
