//
//  GreenfootModal.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/29/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation

class GreenfootModal {
    static let sharedInstance = GreenfootModal()
    var electricData:GreenData
    init() {
        electricData = GreenData(name: "Electric", xLabel:"Month", yLabel: "kWh")
        electricData.data["Lightbulbs"] = 0;
        electricData.data["Appliances"] = 0;
        electricData.data["SolarPanels"] = 0;
    }
}

class GreenData {
    var dataName:String
    var data:[String:Int]

    private var graphData:[Date: Double]
    var xLabel:String
    var yLabel:String
    
    init(name:String, xLabel:String, yLabel:String) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        data = [:]
        dataName = name
        graphData = [:]
    }
    
    func addDataPoint(month:Date, y:Double) {
        graphData[month] = y
    }
    
    func getGraphData() -> [Date: Double] {
        return graphData
    }
}
