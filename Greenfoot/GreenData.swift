//
//  GreenData.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/14/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit
import Material
import CoreData

class GreenData {
    var dataName:String
    var data:[String:Int]
    var baselines:[String:Int]
    var bonusDict:[String:Int]
    
    var descriptions: [String:String]
    
    var averageLabel:String
    var icon:UIImage
    
    var calculateEP: (Double, Double) -> Int
    var calculateCO2: (Double) -> Double
    var bonus: (Int, Int) -> Int
    
    var graphData:[Date: Double]
    var epData:[Date: Int]
    var co2Equivalent:[Date: Double]
    
    var uploadedData:[String]
    
    //Returns the average daily usage. Displays on each data tab
    var averageValue:Double {
        get {
            var sum = 0.0
            var nums = 0.0
            for (_, value) in graphData {
                sum += value/31
                nums += 1
            }
            if nums == 0.0 {
                return 0
            }
            var ans = sum/nums
            ans *= 10
            let rounded = Int(ans)
            return Double(rounded)/10.0
        }
    }
    
    //Returns the average daily carbon emission
    var averageCarbon:Double {
        get{
            let count = Double(getCarbonData().keys.count) * 31.0
            
            if count == 0 {
                return 0
            }
            
            var value = Double(totalCarbon)/count
            value *= 10
            let rounded = Int(value)
            return Double(rounded)/10.0
        }
    }
    
    var xLabel:String
    var yLabel:String
    
    var energyPoints:Int
    var totalCarbon: Int
    
    var baseline:Double
    var stateConsumption: Double?
    
    init(name:String, xLabel:String, yLabel:String, base: Double, averageLabel:String, icon:UIImage) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        data = [:]
        baselines = [:]
        bonusDict = [:]
        
        descriptions = [:]
        uploadedData = []
        
        dataName = name
        
        graphData = [:]
        epData = [:]
        co2Equivalent = [:]
        
        energyPoints = 0
        totalCarbon = 0
        
        baseline = base
        self.averageLabel = averageLabel
        self.icon = icon
        
        bonus = {
            base, attr in
            return (attr > base) ? 5*(attr-base) : 0
        }
        
        calculateCO2 = {
            point in
            return point
        }
        
        self.calculateEP = {
            base, point in
            
            let diff = (base-point)/100
            return Int(floor(diff))
        }
    }
    
    func addDataPoint(month:Date, y:Double, save: Bool) {
        graphData[month] = y
        
        let ep = calculateEP(baseline, y)
        epData[month] = ep
        energyPoints += ep
        
        let carbon = calculateCO2(y)
        co2Equivalent[month] = carbon
        totalCarbon += Int(carbon)
        
        if save {
            CoreDataHelper.save(data: self, month: month, amount: y)
            
            //If save is true, that means its a new data point, so you want to try uploading to the server
            addToServer(month: Date.monthFormat(date: month), point: y)
        }
    }
    
    func getGraphData() -> [Date: Double] {
        return graphData
    }
    func getEPData() -> [Date: Int] {
        return epData
    }
    func getCarbonData() -> [Date: Double] {
        return co2Equivalent
    }
    
    func editDataPoint(month:Date, y:Double) {
        let epPrev = epData[month]!
        let carbonPrev = co2Equivalent[month]!
        
        graphData[month] = y
        
        let ep = calculateEP(baseline, y)
        epData[month] = ep
        energyPoints = energyPoints - epPrev + ep
        
        let carbon = calculateCO2(y)
        co2Equivalent[month] = carbon
        totalCarbon = totalCarbon - Int(carbonPrev) + Int(carbon)
        
        //If the data is uploaded, update it, else, upload it
        let date = Date.monthFormat(date: month)
        if let index = uploadedData.index(of: date) {
            CoreDataHelper.update(data: self, month: month, updatedValue: y, uploaded: false)
            uploadedData.remove(at: index)
            updateOnServer(month: date, point: y)
        } else {
            let reqId = [APIRequestType.update.rawValue, dataName, date].joined(separator: ":")
            if !(APIRequestManager.sharedInstance.requestExists(reqId)) {
                CoreDataHelper.update(data: self, month: month, updatedValue: y, uploaded: false)
                addToServer(month: date, point: y)
            } else {
                print("Did not add data because a request was present")
            }
        }
    }
    
    func removeDataPoint(month:Date) {
        graphData.removeValue(forKey: month)
        let carbon = co2Equivalent.removeValue(forKey: month)!
        let ep = epData.removeValue(forKey: month)!
        
        totalCarbon -= Int(carbon)
        energyPoints -= ep
        
        CoreDataHelper.delete(data: self, month: month)
        
        deleteFromServer(month: Date.monthFormat(date: month))
    }
    
    func recalculateEP() {
        energyPoints = 0
        
        for key in bonusDict.keys {
            energyPoints += bonus(baselines[key]!, bonusDict[key]!)
        }
        
        for x in graphData.keys {
            energyPoints += calculateEP(baseline, graphData[x]!)
        }
    }
    
    func recalculateCarbon() {
        totalCarbon = 0
        for (key, value) in graphData {
            let carbon = calculateCO2(value)
            
            totalCarbon += Int(carbon)
            co2Equivalent[key] = carbon
        }
    }
    
    func fetchEGrid() {
        if dataName != GreenDataType.electric.rawValue {
            return
        }
        
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        guard let zip = locality["Zip"] else {
            return
        }
        
        let parameters:[String:String] = ["zip":zip]
        let id = [APIRequestType.get.rawValue, "EGRID"].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "getFromEGrid", withParameters: parameters, andSuccessFunction: {
            data in
            
            let e_factor = data["e_factor"] as! Double
            UserDefaults.standard.set(e_factor, forKey: "e_factor")
            
            self.calculateCO2 = {
                point in
                return point * e_factor/1000
            }
            
            self.recalculateCarbon()
        }, andFailureFunction: nil)
    }
    
    func fetchConsumption() {
        if dataName != GreenDataType.electric.rawValue {
            return
        }
        
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        
        var parameters:[String:String] = ["type":GreenDataType.electric.rawValue]
        parameters["state"] = locality["State"]!
        parameters["country"] = locality["Country"]!
        
        let id=[APIRequestType.get.rawValue, "CONSUMPTION", dataName].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "getFromConsumption", withParameters: parameters, andSuccessFunction: {
            data in
            
            let consumption = data["Consumption"] as! Double
            self.stateConsumption = consumption
            print("State consumption is \(self.stateConsumption!)")
        }, andFailureFunction: nil)
    }
    
    func addToServer(month:String, point:Double) {
        //This is the check to see if the user wants to share their data
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month, "amount":Int(point)]
        parameters["profId"] = SettingsManager.sharedInstance.profile["profId"]!
        parameters["dataType"] = dataName
        
        parameters["city"] = locality["City"]!
        parameters["state"] = locality["State"]
        parameters["country"] = locality["Country"]
        
        let id=[APIRequestType.add.rawValue, dataName, month].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "logData", withParameters: parameters, andSuccessFunction: {
            data in
            
            self.uploadedData.append(month)
            CoreDataHelper.update(data: self, month: Date.monthFormat(string: month), updatedValue: point, uploaded: true)
        }, andFailureFunction: nil)
    }
    
    func reachConsensus() {
        print("Attepting to reach consensus")
        consensusFor("Bonus")
        consensusFor("Data")
        pointConsensus()
    }
    
    func pointConsensus() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        let id = [APIRequestType.consensus.rawValue, dataName].joined(separator: ":")
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataName]
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "fetchData", withParameters: parameters, andSuccessFunction: {
            data in
            
            guard let serverData = data["Data"] as? NSArray else {
                return
            }
            
            for point in serverData {
                let month = (point as! NSDictionary)["Month"]! as! String
                let amount = (point as! NSDictionary)["Amount"]! as! Double
                
                let date = formatter.date(from: month)!
                
                let contains = self.containsPoint(month: date, amount: amount)
                if  contains && self.graphData[date] != amount {
                    //Triggers if the device has the point saved but is an outdated value
                    print("Editing data point")
                    self.editDataPoint(month: date, y: amount)
                } else if !contains {
                    //Triggers if the device doesn't have the point
                    print("Adding data point")
                    self.addDataPoint(month: date, y: amount, save: false)
                }
            }
        }, andFailureFunction: nil)
        
        for (month, amount) in graphData {
            let date = formatter.string(from: month)
            if !uploadedData.contains(date) {
                print("Found unuploaded point")
                addToServer(month: date, point: amount)
            }
        }
    }
    func consensusFor(_ type:String) {
        var dict = (type == "Bonus") ? bonusDict : data
        let id = [APIRequestType.consensus.rawValue, dataName, type].joined(separator: ":")
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataName, "assoc":type]
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "fetchData", withParameters: parameters, andSuccessFunction: {
            data in
            
            guard let serverData = data["Data"] as? NSArray else {
                return
            }
            
            var uploadedAttrs:[String] = []
            for point in serverData {
                guard let pointInfo = point as? NSDictionary else {
                    return
                }
                
                let value = pointInfo["Amount"]! as! Int
                let dataType = pointInfo["DataType"]! as! String
                let attrName = dataType.components(separatedBy: ":")[2]
                uploadedAttrs.append(attrName)
                if let amount = dict[attrName] {
                    if amount != value {
                        print("Editing Bonus Attr")
                        dict[attrName] = value
                    }
                } else {
                    dict[attrName] = value
                }
            }
            
            for (key, value) in dict {
                if !uploadedAttrs.contains(key) {
                    self.logAttribute(key, withValue: value, ofType:type)
                }
            }
        }, andFailureFunction: {
            errorDict in
            if errorDict["Error"] as? APIError == .serverFailure {
                for (key, value) in dict {
                    self.logAttribute(key, withValue: value, ofType:type)
                }
            }
        })
    }
    
    fileprivate func containsPoint(month:Date, amount:Double) -> Bool {
        if let _ = graphData[month] {
            return true
        } else {
            return false
        }
    }
    
    func updateOnServer(month:String, point: Double) {
        //This is the check to see if the user wants to share their data
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month, "amount":Int(point)]
        parameters["profId"] = SettingsManager.sharedInstance.profile["profId"]!
        parameters["dataType"] = dataName
        
        parameters["city"] = locality["City"]!
        parameters["state"] = locality["State"]
        parameters["country"] = locality["Country"]
        
        let id=[APIRequestType.update.rawValue, dataName, month].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "logData", withParameters: parameters, andSuccessFunction: {
            data in
            
            self.uploadedData.append(month)
            CoreDataHelper.update(data: self, month: Date.monthFormat(string: month), updatedValue: point, uploaded: true)
        }, andFailureFunction: nil)
    }
    
    fileprivate func deleteFromServer(month: String) {
        //This is the check to see if the user wants to share their data
        guard let _ = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month]
        parameters["profId"] = SettingsManager.sharedInstance.profile["profId"]!
        parameters["dataType"] = dataName

        let id=[APIRequestType.delete.rawValue, dataName, month].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "deleteDataPoint", withParameters: parameters, andSuccessFunction: nil, andFailureFunction: nil)
    }
    
    func logAttribute(_ attribute:String, withValue value:Int, ofType type:String) {
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":"NA", "amount":value]
        parameters["profId"] = SettingsManager.sharedInstance.profile["profId"]!
        parameters["dataType"] = [dataName, type, attribute].joined(separator: ":")
        
        parameters["city"] = locality["City"]!
        parameters["state"] = locality["State"]
        parameters["country"] = locality["Country"]
        
        let id=[APIRequestType.log.rawValue, dataName, attribute].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "logData", withParameters: parameters, andSuccessFunction: nil, andFailureFunction: nil)
    }
}
