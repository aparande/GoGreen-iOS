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

class GraphViewController: UIViewController, ChartViewDelegate, InputToolbarDelegate {

    private let greenModal = GreenfootModal.sharedInstance
    private weak var data: GreenData!
    private var datapoints: [GreenDataPoint] {
        return data.getGraphData().reversed()
    }
    
    private var location: Int!{
        didSet {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        prepNavigationBar(titled: data.dataName)
        
        setupMainGraph()
        setupToolbar()
        
        self.location = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mainGraph.loadDataFrom(array: data.getGraphData(), labeled: "kWh")
    }
    
    @IBAction func addData(_ sender: Any) {
        let bulkAdder = BulkDataViewController(withData: self.data)
        let nvc = NavigationController(rootViewController: bulkAdder)
        self.present(nvc, animated: true, completion: nil)
    }
    
    func setDataType(data:GreenData) {
        //assertionFailure("You need to override this method. Something like data=GreenfootModal.electricData should be put here")
        self.data = data
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
}
