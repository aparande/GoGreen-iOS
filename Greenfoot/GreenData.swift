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
    
    //var uploadedData:[String]
    
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
        //uploadedData = []
        
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
            let dateString = Date.monthFormat(date: month)
            let parameters:[String:Any] = ["month":dateString, "amount":Int(y), "dataType": dataName]
            let id=[APIRequestType.log.rawValue, dataName, dateString].joined(separator: ":")
            makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
        }
    }
    
    func updateTotals(afterMonth month:Date, changedTo y: Double) {
        let epPrev = epData[month]!
        let carbonPrev = co2Equivalent[month]!
        
        graphData[month] = y
        
        let ep = calculateEP(baseline, y)
        epData[month] = ep
        energyPoints = energyPoints - epPrev + ep
        
        let carbon = calculateCO2(y)
        co2Equivalent[month] = carbon
        totalCarbon = totalCarbon - Int(carbonPrev) + Int(carbon)
    }
    
    func editDataPoint(month:Date, y:Double) {
        updateTotals(afterMonth: month, changedTo: y)
        
        //If the data is uploaded, update it, else, upload it
        let date = Date.monthFormat(date: month)
        
        let reqId = [APIRequestType.update.rawValue, dataName, date].joined(separator: ":")
        if !(APIRequestManager.sharedInstance.requestExists(reqId)) {
            CoreDataHelper.update(data: self, month: month, updatedValue: y)
            
            let dateString = Date.monthFormat(date: month)
            let parameters:[String:Any] = ["month":dateString, "amount":Int(y), "dataType": dataName]
            let id=[APIRequestType.log.rawValue, dataName, dateString].joined(separator: ":")
            makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
        } else {
            print("Did not add data because a request was present")
        }
    }
    
    func removeDataPoint(month:Date) {
        graphData.removeValue(forKey: month)
        let carbon = co2Equivalent.removeValue(forKey: month)!
        let ep = epData.removeValue(forKey: month)!
        
        totalCarbon -= Int(carbon)
        energyPoints -= ep
        
        CoreDataHelper.delete(data: self, month: month)
        
        let dateString = Date.monthFormat(date: month)
        let parameters:[String:Any] = ["month":dateString, "dataType": dataName]
        let id = [APIRequestType.delete.rawValue, dataName, dateString].joined(separator: ":")
        makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withLocationData: false)
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
            
            self.recalculateEP()
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
    
    func makeServerCall(withParameters parameters: [String:Any], identifiedBy id: String, atEndpoint endpoint:String, withLocationData sendLocation: Bool) {
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var params = parameters
        params["profId"] = SettingsManager.sharedInstance.profile["profId"]!
        
        if sendLocation {
            params["city"] = locality["City"]!
            params["state"] = locality["State"]
            params["country"] = locality["Country"]
        }
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: endpoint, withParameters: params, andSuccessFunction: nil, andFailureFunction: nil)
    }
    
    func reachConsensus() {
        print("Attepting to reach consensus")
        consensusFor("Bonus", completion: nil)
        consensusFor("Data", completion: nil)
        pointConsensus()
    }
    
    func pointConsensus() {
        let upload:([Date]?) -> Void = {
            uploadedPoints in
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/yy"
            
            let logToServer:(Date, Double) -> Void = {
                month, amount in
                let dateString = Date.monthFormat(date: month)
                let parameters:[String:Any] = ["month":dateString, "amount":Int(amount), "dataType": self.dataName]
                let id=[APIRequestType.log.rawValue, self.dataName, dateString].joined(separator: ":")
                self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
            }
            
            if let _ = uploadedPoints {
                for (month, amount) in self.graphData {
                    if !uploadedPoints!.contains(month) {
                        print("Found unuploaded point")
                        logToServer(month, amount)
                    }
                }
            } else {
                for (month, amount) in self.graphData {
                    logToServer(month, amount)
                }
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        let id = [APIRequestType.consensus.rawValue, dataName].joined(separator: ":")
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataName]
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "fetchData", withParameters: parameters, andSuccessFunction: {
            data in
            
            guard let serverData = data["Data"] as? NSArray else {
                return
            }
            
            var uploadedPoints:[Date] = []
            for point in serverData {
                guard let pointInfo = point as? NSDictionary else {
                    return
                }
                
                let month = pointInfo["Month"]! as! String
                let amount = pointInfo["Amount"]! as! Double
                
                let date = formatter.date(from: month)!
                uploadedPoints.append(date)
                
                if let point = self.graphData[date] {
                    if point != amount {
                        //Triggers if the device has the point saved but is an outdated value
                        print("Editing point")
                        self.editDataPoint(month: date, y: amount)
                    }
                } else {
                    self.addDataPoint(month: date, y: amount, save: false)
                }
            }
            
            upload(uploadedPoints)
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                upload(nil)
            }
        })
    }
    
    func consensusFor(_ type:String, completion: ((Bool) -> Void)?) {
        var dict = (type == "Bonus") ? bonusDict : data
        let id = [APIRequestType.consensus.rawValue, dataName, type].joined(separator: ":")
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataName, "assoc":type]
        
        let logToServer:(String, Int) -> Void = {
            key, value in
            var parameters:[String:Any] = ["month":"NA", "amount":value]
            parameters["dataType"] = [self.dataName, type, key].joined(separator: ":")
            let id=[APIRequestType.log.rawValue, self.dataName, key].joined(separator: ":")
            self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
        }
        
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
                    logToServer(key, value)
                }
            }
            
            completion?(true)
            
            UserDefaults.standard.set(dict, forKey: self.dataName+":\(type.lowercased())")
        }, andFailureFunction: {
            errorDict in
            if errorDict["Error"] as? APIError == .serverFailure {
                for (key, value) in dict {
                    logToServer(key, value)
                }
            }
            completion?(false)
        })
    }
    
    fileprivate func containsPoint(month:Date, amount:Double) -> Bool {
        if let _ = graphData[month] {
            return true
        } else {
            return false
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
}
