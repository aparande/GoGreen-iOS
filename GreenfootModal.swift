//
//  GreenfootModal.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/29/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

class GreenfootModal {
    static let sharedInstance = GreenfootModal()
    var electricData:GreenData
    
    init() {
        /* https://www.eia.gov/tools/faqs/faq.cfm?id=97&t=3 */
        electricData = GreenData(name: "Electric", xLabel:"Month", yLabel: "kWh", base: 901)
        electricData.data["Solar Panels"] = 13
        /*http://solarexpert.com/2013/11/07/how-many-solar-panels-are-needed-for-a-2000-square-foot-home/  */
        electricData.baselines["Solar Panels"] = 12
    }
}

class GreenData {
    var dataName:String
    var data:[String:Int]
    var baselines:[String:Int]

    private var graphData:[Date: Double]
    var averageValue:Double {
        get {
            var sum = 0.0
            var nums = 0.0
            for (_, value) in graphData {
                sum += value/31
                nums += 1
            }
            var ans = sum/nums
            ans *= 10
            let rounded = Int(ans)
            return Double(rounded)/10.0
        }
    }
    
    var xLabel:String
    var yLabel:String
    
    var energyPoints:Int
    var baseline:Double
    
    init(name:String, xLabel:String, yLabel:String, base: Double) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        data = [:]
        baselines = [:]
        dataName = name
        graphData = [:]
        energyPoints = 0
        baseline = base
    }
    
    func addDataPoint(month:Date, y:Double) {
        graphData[month] = y
        energyPoints += calculateEP(base: baseline, point: y)
    }
    
    func getGraphData() -> [Date: Double] {
        return graphData
    }
    
    func calculateEP(base:Double, point: Double) -> Int {
        //Get a more complicated function here
        return Int(base - point)
    }
    
    func bonus(base:Int, attr: Int) -> Int {
        return (attr > base) ? 5*(attr-base) : 0
    }
    
    func recalculateEP() {
        energyPoints = 0
        for key in data.keys {
            energyPoints += bonus(base:baselines[key]!, attr:data[key]!)
        }
        
        for x in graphData.keys {
            energyPoints += calculateEP(base:baseline, point:graphData[x]!)
        }
    }
}

struct Colors {
    static let green = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
}
