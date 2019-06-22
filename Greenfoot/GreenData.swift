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
    #warning("Why isn't this GreenDataType")
    var dataName:String
    var data:[String:GreenAttribute]
    var baselines:[String:Int]
    var bonusDict:[String:GreenAttribute]
    
    var descriptions: [String:String]
    
    var averageLabel:String
    var icon:UIImage
    
    var calculateEP: (Double, Double) -> Int
    var calculateCO2: (Double) -> Double
    var bonus: (Int, Int) -> Int
    
    var graphData:[GreenDataPoint]
    var epData:[GreenDataPoint]
    var co2Equivalent:[GreenDataPoint]
    
    //Returns the average daily usage. Displays on each data tab
    var averageValue:Double {
        get {
            var sum = 0.0
            var nums = 0.0
            for point in graphData {
                sum += point.value/31
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
            //FLAG IS THIS CORRECT?
            let count = Double(co2Equivalent.count) * 31.0
            
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
        
        dataName = name
        
        graphData = []
        epData = []
        co2Equivalent = []
        
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
    
    
    func addDataPoint(point: GreenDataPoint, save: Bool, upload: Bool) {
        graphData.append(point)
        
        let ep = calculateEP(baseline, point.value)
        let energyPoint = GreenDataPoint(month: point.month, value: Double(ep), dataType: dataName, pointType: .energy)
        epData.append(energyPoint)
        energyPoints += ep
        
        let carbon = calculateCO2(point.value)
        let carbonPoint = GreenDataPoint(month: point.month, value: carbon, dataType: dataName, pointType: .carbon)
        co2Equivalent.append(carbonPoint)
        totalCarbon += Int(carbon)
        
        if save {
            CoreDataHelper.save(dataPoint: point)
            
            sortData()
        }
        
        if upload {
            //If save is true, that means its a new data point, so you want to try uploading to the server
            FirebaseUtils.logData(point)
        }
    }
    
    func sortData() {
        let sorter: (GreenDataPoint, GreenDataPoint) -> Bool = {
            (point1, point2) -> Bool in
            return point1.month.compare(point2.month) == ComparisonResult.orderedAscending
        }
        graphData.sort(by: sorter)
        epData.sort(by: sorter)
        co2Equivalent.sort(by: sorter)
    }
    
    /**
        Update the DataPoint at the given index and update all total values
        - parameter index: the index to update
        - parameter newVal: the new value of the datapoint
    */
    func updateTotals(atIndex index: Int, changedTo newVal: Double) {
        let ep = calculateEP(baseline, newVal)
        let carbon = calculateCO2(newVal)
        
        let _ = graphData[index].updateValue(to: newVal)
        let epPrev = epData[index].updateValue(to: Double(ep))
        let carbonPrev = co2Equivalent[index].updateValue(to: carbon)

        energyPoints = energyPoints - Int(epPrev) + Int(ep)
        totalCarbon = totalCarbon - Int(carbonPrev) + Int(carbon)
    }
    
    func editDataPoint(atIndex index: Int, toValue newVal:Double) {
        updateTotals(atIndex: index, changedTo: newVal)
        
        //If the data is uploaded, update it, else, upload it
        let dataPoint = graphData[index]
        CoreDataHelper.update(point: dataPoint)
        FirebaseUtils.editData(dataPoint)
    }
    
    func removeDataPoint(atIndex index:Int, fromServer shouldDeleteFromServer: Bool) {
        let dataPoint = graphData.remove(at: index)
        let carbonPoint = co2Equivalent.remove(at: index)
        let energyPoint = epData.remove(at: index)
        
        totalCarbon -= Int(carbonPoint.value)
        energyPoints -= Int(energyPoint.value)
        
        if shouldDeleteFromServer {
            deletePointOnServer(dataPoint)
        }
    }
    
    func recalculateEP() {
        energyPoints = 0
        
        for key in bonusDict.keys {
            energyPoints += bonus(baselines[key]!, bonusDict[key]!.value)
        }
        
        for i in 0..<graphData.count {
            let dataPoint = graphData[i]
            let newEP = calculateEP(baseline, dataPoint.value)
            epData[i].value = Double(newEP)
            energyPoints += newEP
        }
    }
    
    func recalculateCarbon() {
        totalCarbon = 0
        for i in 0..<graphData.count {
            let dataPoint = graphData[i]
            
            let carbon = calculateCO2(dataPoint.value)
            co2Equivalent[i].value = carbon
            totalCarbon += Int(carbon)
        }
    }
    
    func fetchEGrid() {
        if dataName != GreenDataType.electric.rawValue {
            return
        }
        
        guard let locality = SettingsManager.sharedInstance.getLocationData() else {
            return
        }
        
        FirebaseUtils.getEGridDataFor(zipCode: locality.zip, andState: locality.state) { (factor) in
            guard let e_factor = factor else {
                return
            }
            
            UserDefaults.standard.set(e_factor, forKey: "e_factor")
            
            self.calculateCO2 = {
                point in
                return point * e_factor/1000
            }
            
            print("EGrid conversion is \(e_factor)")
            
            self.recalculateEP()
            self.recalculateCarbon()
        }
    }
    
    func fetchConsumption() {
        if dataName != GreenDataType.electric.rawValue {
            return
        }
        
        guard let locality = SettingsManager.sharedInstance.getLocationData() else {
            return
        }
        
        FirebaseUtils.getAverageFor(state: locality.state, type: .electric) { (value) in
            self.stateConsumption = value
            print("State consumption is \(self.stateConsumption!)")
        }
    }
    
    func deletePointOnServer(_ dataPoint: GreenDataPoint) {
        //Prepare for server call
        guard let _ = SettingsManager.sharedInstance.getLocationData() else {
            return
        }
        //Set server call parameters
        let dateString = Date.monthFormat(date: dataPoint.month)
        let id = [APIRequestType.delete.rawValue, dataName, dateString].joined(separator: ":")
        var parameters:[String:Any] = ["month":dateString, "dataType": dataName]
        parameters["profId"] = SettingsManager.sharedInstance.profile.id!
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "deleteDataPoint", withParameters: parameters, andSuccessFunction: {
            (success) in
            //If the server sucessfully marks the point as deleted, then there is no reason to keep it saved on the device
            print("Yay server marked it")
            CoreDataHelper.delete(point: dataPoint)
        }, andFailureFunction: {
            (errorDict) in
            //If the server does not mark the point as deleted, mark it as deleted on the device
            print ("Rip no server")
            dataPoint.delete()
            CoreDataHelper.update(point: dataPoint)
        })
    }
    
    func makeServerCall(withParameters parameters: [String:Any], identifiedBy id: String, atEndpoint endpoint:String, containingLocation shouldSendLocation: Bool) {
        if let params = setupServerCall(withParameters: parameters, containingLocation: shouldSendLocation) {
            APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: endpoint, withParameters: params, andSuccessFunction: nil, andFailureFunction: nil)
        }
    }
    
    func makeServerCall(withParameters parameters: [String:Any], identifiedBy id:String, atEndpoint endpoint:String, withSuccessFunction success: @escaping (NSDictionary) -> Void, andFailureFunction failure: @escaping (NSDictionary) -> Void) {
        if let params = setupServerCall(withParameters: parameters, containingLocation: false) {
            APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: endpoint, withParameters: params, andSuccessFunction: success, andFailureFunction: failure)
        }
    }
    
    //Sets up the server call by adding certain things to the parameters. Returns nil if the call should not continue
    private func setupServerCall(withParameters parameters: [String:Any], containingLocation shouldSendLocation: Bool) -> [String:Any]? {
        guard let locality = SettingsManager.sharedInstance.getLocationData() else {
            return nil
        }
        
        var params = parameters
        params["profId"] = SettingsManager.sharedInstance.profile.id!
        
        if shouldSendLocation {
            params["city"] = locality.city
            params["state"] = locality.state
            params["country"] = locality.country
        }
        
        return params
    }
    
    func reachConsensus() {
        print("Attepting to reach consensus")
        
        FirebaseUtils.getDataForType(dataName) {
            (serverData) in
            
            var unUploadedPoints:[GreenDataPoint?] = self.graphData
            let storedGraphData = self.graphData
            
            for point in serverData {
                let index = self.indexOfPointForDate(point.month, inArray: storedGraphData)
                //If the point is not deleted, then add it to the device, but check that the device didn't delete it before it is added to the device
                if index == -1 {
                    self.addDataPoint(point: point, save: true, upload: false)
                } else {
                    let savedPoint = storedGraphData[index]
                    
                    //The only case in which a point in which a point is not sent to the server is when the server is newer, hence there  being only one place unUploadedPoints[index] = nil
                    if savedPoint.value != point.value && savedPoint.lastUpdated < point.lastUpdated {
                        unUploadedPoints[index] = nil
                        print("Editing point")
                        self.editDataPoint(atIndex: index, toValue: point.value)
                    }
                }
            }
            
            self.sortData()
            
            for dataPoint in unUploadedPoints {
                guard let point = dataPoint else {
                    continue
                }
                
                FirebaseUtils.logData(point)
            }
        }
    }
    
    func findPointForDate(_ date: Date, inArray arr:[GreenDataPoint]) -> GreenDataPoint? {
        for point in arr {
            if (date == point.month) {
                return point
            }
        }
        
        return nil
    }
    
    func findPointForDate(_ date: Date, ofType type: DataPointType) -> GreenDataPoint? {
        var dataArr = graphData
        switch type {
        case .energy:
            dataArr = epData
            break
        case .carbon:
            dataArr = co2Equivalent
            break
        default:
            break
        }
        
        for point in dataArr {
            if (date == point.month) {
                return point
            }
        }
        
        return nil
    }
    
    func indexOfPointForDate(_ date: Date, inArray arr:[GreenDataPoint]) -> Int {
        for i in 0..<arr.count {
            if (date == arr[i].month) {
                return i
            }
        }
        
        return -1
    }
    
    func indexOfPointForDate(_ date: Date, ofType type: DataPointType) -> Int {
        var dataArr = graphData
        switch type {
        case .energy:
            dataArr = epData
            break
        case .carbon:
            dataArr = co2Equivalent
            break
        default:
            break
        }
        
        var index = 0
        for point in dataArr {
            if (date == point.month) {
                return index
            }
            index += 1
        }
        
        return -1
    }
    
    func getGraphData() -> [GreenDataPoint] {
        return graphData
    }
    func getEPData() -> [GreenDataPoint] {
        return epData
    }
    func getCarbonData() -> [GreenDataPoint] {
        return co2Equivalent
    }
}
