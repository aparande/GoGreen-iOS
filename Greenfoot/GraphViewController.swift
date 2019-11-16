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

class GraphViewController: SourceAggregatorViewController, ChartViewDelegate, InputToolbarDelegate {    
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
    @IBOutlet weak var monthGraph: HorizontalBarGraph!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        prepNavigationBar(titled: dataSource.name)
        setupNavButtons()
        
        setupMainGraph()
        setupToolbar()
        
        self.location = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        for point in aggregator.points {
            print("\((point.month as Date).toString(withFormat: "MM-YYYY")): \(point.rawValue))")
        }
        mainGraph.loadDataFrom(array: aggregator.points, labeled: aggregator.unit.name)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func addData(_ sender: Any) {
        presentBulletin(forSource: self.dataSource)
    }
    
    override func onBLTNPageItemActionClicked(with source: CarbonSource) {
        super.onBLTNPageItemActionClicked(with: source)
        
        mainGraph.loadDataFrom(array: aggregator.points, labeled: aggregator.unit.name)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? BulkDataViewController {
            dest.source = self.dataSource
        }
    }
    
    @objc func goToSettings() {
        let svc = SettingsViewController(withSource: self.dataSource)
        self.navigationController?.pushViewController(svc, animated: true)
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
    
    fileprivate func setupNavButtons() {
        let settingsButton = UIBarButtonItem(image: Icon.cm.settings, style: .plain, target: self, action: #selector(goToSettings))
        self.navigationItem.setRightBarButton(settingsButton, animated: true)
    }
    
    static func instantiate(for source: CarbonSource) -> GraphViewController{
        let graphVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GraphView") as! GraphViewController
        graphVC.dataSource = source
        return graphVC
    }
}
