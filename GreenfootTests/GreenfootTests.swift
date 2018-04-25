//
//  GreenfootTests.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 3/15/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import XCTest
import Foundation
@testable import Greenfoot

class GreenfootTests: XCTestCase {
    
    var electricData: GreenData!
    var allData: NSDictionary!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let  electricData = GreenData(name: GreenDataType.electric.rawValue, xLabel:"Month", yLabel: "kWh", base: 901, averageLabel:"kWh per Day", icon:UIImage())
        electricData.baselines["Solar Panels"] = 12
        
        let path = Bundle.main.path(forResource: "TestCases", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        
        allData = dict!.object(forKey: "Root") as! NSDictionary
        guard let electricityDownloaded = allData["ElectricityDownloaded"] as? NSArray else {
            return
        }
        
        for point in electricityDownloaded {
            guard let pointInfo = point as? NSDictionary else {
                return
            }
            
            let month = pointInfo["Month"]! as! String
            let amount = pointInfo["Amount"]! as! Double
            let lastUpdated = pointInfo["LastUpdated"]! as! Double
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            let date = formatter.date(from: month)!
            
            let dataPoint = GreenDataPoint(month: date, value: amount, dataType: "Electricity", lastUpdated: Date(timeIntervalSince1970: lastUpdated))
            electricData.addDataPoint(point: dataPoint, save: false)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        allData = nil
        electricData = nil
        super.tearDown()
    }
    
    func testPointConsensus() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        guard let serverData = allData["ElectricityUploaded"] as? NSArray else {
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        var unUploadedPoints:[GreenDataPoint?] = electricData.graphData
        for point in serverData {
            guard let pointInfo = point as? NSDictionary else {
                return
            }
            
            let month = pointInfo["Month"]! as! String
            let amount = pointInfo["Amount"]! as! Double
            let lastUpdated = pointInfo["LastUpdated"]! as! Double
            
            
            let date = formatter.date(from: month)!
            
            let index = electricData.indexOfPointForDate(date, inArray: electricData.graphData)
            if index == -1 {
                let dataPoint = GreenDataPoint(month: date, value: amount, dataType: "Electricity", lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                electricData.addDataPoint(point: dataPoint, save: false)
            } else {
                let point = electricData.graphData[index]
                unUploadedPoints[index] = nil
                if point.value != amount && point.lastUpdated.timeIntervalSince1970 < lastUpdated {
                    //Triggers if the device has the point saved but is an outdated value
                    print("Editing point")
                    electricData.editDataPoint(atIndex: index, toValue: amount)
                }
            }
        }
        
        let result = ["01/18", "02/18"]
        for greenDataPoint in unUploadedPoints {
            if let point = greenDataPoint {
                if result.contains(formatter.string(from: point.month)) {
                    XCTAssert(false)
                }
            }
        }
    }
}
