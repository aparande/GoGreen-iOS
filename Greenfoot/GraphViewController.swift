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

class GraphViewController: SourceAggregatorViewController, ChartViewDelegate, InputToolbarDelegate, BLTNPageItemDelegate {

    private let greenModal = GreenfootModal.sharedInstance
    
    var dataSource: CarbonSource! {
        didSet {
            #warning("Uninjected dependecy")
            self.aggregator = SourceAggregator(fromSources: [self.dataSource])
        }
    }

    private var datapoints: [Measurement] {
        return aggregator.points.reversed()
    }
    
    private var location: Int!{
        didSet {
            if aggregator.points.count == 0 {
                return
            }
            
            let datapoint = aggregator.points[self.location]
            toolbar.centerField.text = Date.monthFormat(date: datapoint.month as Date)
            
            var dict = ["You":datapoint.rawValue]

            #warning("Inelegant")
            if let cdp = datapoint as? CarbonDataPoint {
                if let cityRef = cdp.reference(atLevel: .city) {
                    dict[cityRef.name] = cityRef.rawValue
                }
                
                if let stateRef = cdp.reference(atLevel: .state) {
                    dict[stateRef.name] = stateRef.rawValue
                }
                
                if let countryRef = cdp.reference(atLevel: .country) {
                    dict[countryRef.name] = countryRef.rawValue
                }
            }
            
            monthGraph.loadData(dict, labeled: "Month Data")
        }
    }
    
    @IBOutlet weak var mainGraph: BarGraph!
    @IBOutlet weak var toolbar: InputToolbar!
    @IBOutlet weak var monthGraph: HorizontalBarChartView!
    
    lazy var bulletinManager: BLTNItemManager = {
        let rootItem: AddDataBLTNItem = AddDataBLTNItem(title: "Add Data", source: self.dataSource)
        rootItem.delegate = self
        return BLTNItemManager(rootItem: rootItem)
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepNavigationBar(titled: dataSource.name)
        
        setupMainGraph()
        setupToolbar()
        
        self.location = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        mainGraph.loadDataFrom(array: aggregator.points, labeled: "kWh")
    }
    
    @IBAction func addData(_ sender: Any) {
        bulletinManager.showBulletin(above: self)
    }
    
    func onBLTNPageItemActionClicked(with source: CarbonSource) {
        aggregator.refresh()
        mainGraph.loadDataFrom(array: aggregator.points, labeled: "kWh")
        bulletinManager.dismissBulletin(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? BulkDataViewController {
            dest.source = self.dataSource
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
    
    static func instantiate(for source: CarbonSource) -> GraphViewController{
        let graphVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        graphVC.dataSource = source
        return graphVC
    }
}
