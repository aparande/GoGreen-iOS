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
import BLTNBoard

class GraphViewController: UIViewController, ChartViewDelegate, InputToolbarDelegate, BLTNPageItemDelegate {

    private let greenModal = GreenfootModal.sharedInstance
    private weak var data: GreenData!
    private var datapoints: [GreenDataPoint] {
        return data.getGraphData().reversed()
    }
    
    private var location: Int!{
        didSet {
            if self.datapoints.count == 0 {
                return
            }
            
            let datapoint = self.datapoints[self.location]
            toolbar.centerField.text = Date.monthFormat(date: datapoint.month)
            
            var dict = ["You":datapoint.value]
            if let consumption = self.data.stateConsumption, let state = greenModal.locality?.state {
                dict[state] = consumption
            }
            
            dict["US"] = data.baseline
            
            monthGraph.loadData(dict, labeled: "Month Data")
        }
    }
    
    @IBOutlet weak var mainGraph: BarGraph!
    @IBOutlet weak var toolbar: InputToolbar!
    @IBOutlet weak var monthGraph: HorizontalBarChartView!
    
    lazy var bulletinManager: BLTNItemManager = {
        let rootItem: AddDataBLTNItem = AddDataBLTNItem(title: "Add Data", data: self.data)
        rootItem.delegate = self
        return BLTNItemManager(rootItem: rootItem)
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        prepNavigationBar(titled: data.dataName)
        
        setupMainGraph()
        setupToolbar()
        
        self.location = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mainGraph.loadDataFrom(array: data.getGraphData(), labeled: "kWh")
    }
    
    @IBAction func addData(_ sender: Any) {
        bulletinManager.showBulletin(above: self)
    }
    
    func onBLTNPageItemActionClicked(with data: GreenData) {
        mainGraph.loadDataFrom(array: data.getGraphData(), labeled: "kWh")
        bulletinManager.dismissBulletin(animated: true)
    }
    
    func setDataType(data:GreenData) {
        //assertionFailure("You need to override this method. Something like data=GreenfootModal.electricData should be put here")
        self.data = data
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? BulkDataViewController {
            dest.data = self.data
        }
    }
    
    func rightTrigger() {
        if location + 1 < self.datapoints.count {
            location += 1
        }
    }
    
    func leftTrigger() {
        if location - 1 > -1 {
            location -= 1
        }
    }
    
    fileprivate func setupToolbar() {
        toolbar.inputDelegate = self
        toolbar.setLeftButton(left: Icon.cm.arrowBack as Any)
        toolbar.setRightButton(right: Icon.cm.arrowBack?.withHorizontallyFlippedOrientation() as Any)
        toolbar.itemTint = UIColor.white
        toolbar.color = Colors.green
    }
    
    fileprivate func setupMainGraph() {
        mainGraph.delegate = self
    }
    
    static func instantiate(for data: GreenData) -> GraphViewController{
        let graphVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        graphVC.setDataType(data: data)
        return graphVC
    }
}
