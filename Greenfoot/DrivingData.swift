//
//  DrivingData.swift
//  Greenfoot
//
//  Created by Anmol Parande on 2/9/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import Foundation
import CoreData
import Material
import UIKit

class DrivingData: GreenData {
    var carData:[String:[Date:Double]]
    var carMileage:[String:Int]

    init() {
        let defaults = UserDefaults.standard
        
        carData = [:]
        
        if let mileages = defaults.dictionary(forKey: "MilesData") as? [String:Int] {
            carMileage = mileages
        } else {
            carMileage = [:]
        }
        
        //https://www.epa.gov/sites/production/files/2016-02/documents/420f14040a.pdf
        //4.7 metric tons/12 = 390 kg
        //The equivalent is 950 miles
        super.init(name: GreenDataType.driving.rawValue, xLabel: "Month", yLabel: "Miles", base: 950, averageLabel: "Miles per Day", icon: Icon.road_emblem)
        
        self.calculateCO2 = {
            miles in
            return 19.6*miles/Double(self.data["Average MPG"]!)
        }
        
        self.calculateEP = {
            base, point in
            let diff = (self.calculateCO2(base) - self.calculateCO2(point))/100
            
            return Int(floor(diff))
        }
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Car")
            do {
                let managedObjects = try managedContext.fetch(fetchRequest)
                
                for managedObj in managedObjects {
                    let name = managedObj.value(forKeyPath: "name") as! String
                    let amount = managedObj.value(forKeyPath: "amount") as! Double
                    let month = managedObj.value(forKeyPath: "month") as! Date
                    
                    if let _ = carData[name] {
                        carData[name]![month] = amount
                    } else {
                        carData[name] = [month:amount]
                    }
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    func compileToGraph() {
        var totalMPG = 0
        for (key, value) in carMileage {
            if carData[key] != nil && carData[key]!.count != 0 {
                totalMPG += value
            }
        }
        
        if totalMPG == 0 || carMileage.count == 0 {
            self.data["Average MPG"] = 0
            self.data["Number of Cars"] = 0
            return
        }
        
        self.data["Average MPG"] = totalMPG/carMileage.count
        self.data["Number of Cars"] = carMileage.count
        
        var dictArr:[[Date:Double]] = []
        for key in carData.keys {
            dictArr.append(carData[key]!)
        }
        
        var dataDict:[[Date:Int]] = []
        //Splits the data so non-consecutive months are split into consecutive ones
        for dict in dictArr {
            var keys:[Date] = []
            for key in dict.keys {
                keys.append(key)
            }
            
            keys.sort(by: {
                (date1, date2) in
                return date1.compare(date2) == ComparisonResult.orderedAscending
            })
            
            var data:[Date:Int] = [:]
            for index in 0..<keys.count-1 {
                let firstKey = keys[index]
                let nextKey = keys[index+1]
                
                let difference = dict[nextKey]!-dict[firstKey]!
                
                let monthDiff =  nextKey.months(from: firstKey)
                let bucketNum = Int(difference)/monthDiff
                
                data[firstKey] = bucketNum
                
                var nextMonth = firstKey.nextMonth()
                
                while nextKey.compare(nextMonth) != ComparisonResult.orderedSame {
                    data[nextMonth] = bucketNum
                    nextMonth = nextMonth.nextMonth()
                }
            }
            dataDict.append(data)
        }
        
        var keys:[Date] = []
        for dict in dataDict {
            for key in dict.keys {
                if !keys.contains(key) {
                    keys.append(key)
                }
            }
        }
        keys.sort(by: {
            (date1, date2) in
            return date1.compare(date2) == ComparisonResult.orderedAscending
        })
        
        var sums:[Date:Int] = [:]
        for key in keys {
            var sum = 0
            for dict in dataDict {
                if let val = dict[key] {
                    sum += val
                }
            }
            sums[key] = sum
        }
        
        for (date, value) in sums {
            let miles = Double(value)
            if let dataPoint = findPointForDate(date, inArray: graphData) {
                editDataPoint(month: date, y: miles)
            } else {
                let dataPoint = GreenDataPoint(month: date, value: miles, dataType: self.dataName)
                addDataPoint(point: dataPoint, save:true)
            }
        }
        
        for point in graphData {
            if !keys.contains(point.month) {
                removeDataPoint(month: point.month)
            }
        }
    }
    
    func addPointToCoreData(car:String, month: Date, point: Double) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.persistentContainer.performBackgroundTask() {
                context in
                
                let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)!
                
                let obj = NSManagedObject(entity: entity, insertInto: context)
                
                obj.setValue(car, forKeyPath: "name")
                obj.setValue(month, forKeyPath: "month")
                obj.setValue(point, forKeyPath: "amount")
                obj.setValue(Date(), forKeyPath: "lastUpdated")
                
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    func deleteCar(_ car:String) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let predicate = NSPredicate(format: "name == %@", argumentArray: [car])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                for entry in fetchedEntities {
                    
                    let name = entry.value(forKeyPath: "name") as! String
                    let month = entry.value(forKeyPath: "month") as! Date
                    
                    let dateString = Date.monthFormat(date:month)
                    var parameters:[String:Any] = ["month":dateString]
                    parameters["dataType"] = dataName+":Point:"+name
                    let id=[APIRequestType.delete.rawValue, dataName, name, dateString].joined(separator: ":")
                    self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withLocationData: false)
                    
                    managedContext.delete(entry)
                }
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        var parameters:[String:Any] = ["month":"NA"]
        parameters["dataType"] = dataName+":Car:"+car
        let id=[APIRequestType.delete.rawValue, dataName, car].joined(separator: ":")
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withLocationData: false)
        
        if carData.keys.count == 0 {
            graphData = []
            epData = []
            co2Equivalent = []
            energyPoints = 0
            totalCarbon = 0
        } else {
            compileToGraph()
            recalculateEP()
            recalculateCarbon()
        }
    }
    
    func deletePointForCar(_ car:String, month:Date) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.persistentContainer.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "name == %@ and month == %@", argumentArray: [car, month])
                
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
                fetchRequest.predicate = predicate
                
                do {
                    let fetchedEntities = try context.fetch(fetchRequest)
                    for entry in fetchedEntities {
                        context.delete(entry)
                    }
                } catch let error as NSError {
                    print("Could not delete. \(error), \(error.userInfo)")
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
        
        let dateString = Date.monthFormat(date:month)
        var parameters:[String:Any] = ["month":dateString]
        parameters["dataType"] = dataName+":Point:"+car
        let id=[APIRequestType.delete.rawValue, dataName, car, dateString].joined(separator: ":")
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withLocationData: false)
    }
    
    func updateCoreDataForCar(car: String, month: Date, amount: Double) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.persistentContainer.performBackgroundTask() {
                context in
                
                let predicate = NSPredicate(format: "name == %@ AND month == %@", argumentArray: [car, month])
                
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
                fetchRequest.predicate = predicate
                
                do {
                    let fetchedEntities = try context.fetch(fetchRequest)
                    fetchedEntities.first?.setValue(amount, forKeyPath: "amount")
                    fetchedEntities.first?.setValue(amount, forKeyPath: "lastUpdated")
                } catch let error as NSError {
                    print("Could not update. \(error), \(error.userInfo)")
                }
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    override func reachConsensus() {
        consensusFor("Bonus", completion:nil)
        consensusFor("Data", completion: {
            success in
            
            if success {
                self.carConsensus()
            }
        })
    }
    
    private func carConsensus() {
        let id = [APIRequestType.consensus.rawValue, dataName, "Cars"].joined(separator: ":")
        let dataType = dataName
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataType, "assoc": "Car"]
        
        let sendToServer:(String, Int) -> Void = {
            car, mileage in
            var parameters:[String:Any] = ["month":"NA", "amount":mileage]
            parameters["dataType"] = [self.dataName, "Car", car].joined(separator: ":")
            let id=[APIRequestType.add.rawValue, self.dataName, car].joined(separator: ":")
            self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
        }
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "fetchData", withParameters: parameters, andSuccessFunction: {
            data in
            
            guard let serverData = data["Data"] as? NSArray else {
                return
            }
            
            var uploadedCars:[String] = []
            for point in serverData {
                guard let pointInfo = point as? NSDictionary else {
                    return
                }
                
                let mileage = pointInfo["Amount"]! as! Int
                let dataType = pointInfo["DataType"]! as! String
                let car = dataType.components(separatedBy: ":")[2]
                
                uploadedCars.append(car)
                
                if let savedMileage = self.carMileage[car] {
                    if savedMileage != mileage {
                        print("Editing car mileage")
                        self.carMileage[car] = mileage
                    }
                } else {
                    self.carMileage[car] = mileage
                }
            }
            
            for (car, mileage) in self.carMileage {
                if !uploadedCars.contains(car) {
                    sendToServer(car, mileage)
                }
            }
            
            self.pointConsensus()
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                for (car, mileage) in self.carMileage {
                    sendToServer(car, mileage)
                }
            }
            
            self.pointConsensus()
        })
    }
    
    override func pointConsensus() {
        let upload:([String]?) -> Void = {
            uploadedPoints in
            
            let sendToServer:(String, Date, Double) -> Void = {
                car, month, amount in
                let dateString = Date.monthFormat(date:month)
                var parameters:[String:Any] = ["month": dateString, "amount":Int(amount)]
                parameters["dataType"] = self.dataName+":Point:"+car
                let id=[APIRequestType.add.rawValue, self.dataName, car, dateString].joined(separator: ":")
                self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", withLocationData: true)
            }
            
            if let _ = uploadedPoints {
                for car in self.carData.keys {
                    for (month, amount) in self.carData[car]! {
                        let date = Date.monthFormat(date: month)
                        let id = [car, date].joined(separator:":")
                        if !uploadedPoints!.contains(id) {
                            print("Found unuploaded odometer point")
                            
                            sendToServer(car, month, amount)
                        }
                    }
                }
            } else {
                for car in self.carData.keys {
                    for (month, amount) in self.carData[car]! {
                        print("Found unuploaded odometer point")
                        sendToServer(car, month, amount)
                    }
                }
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        let id = [APIRequestType.consensus.rawValue, dataName, "carpoints"].joined(separator: ":")
        let dataType = dataName
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataType, "assoc": "Point"]
        
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "fetchData", withParameters: parameters, andSuccessFunction: {
            data in
            
            guard let serverData = data["Data"] as? NSArray else {
                return
            }
            
            var uploadedPoints:[String] = []
            for point in serverData {
                guard let pointInfo = point as? NSDictionary else {
                    return
                }
                
                let month = pointInfo["Month"]! as! String
                let amount = pointInfo["Amount"]! as! Double
                let dataType = pointInfo["DataType"]! as! String
                
                let car = dataType.components(separatedBy: ":")[2]
                let date = formatter.date(from: month)!
                
                uploadedPoints.append(car+":"+month)
                
                if let savedPoints = self.carData[car] {
                    
                    if let point = savedPoints[date] {
                        if point != amount {
                            //Triggers if the device has the point saved but is an outdated value
                            print("Editing odometer point")
                            self.carData[car]![date] = amount
                            self.updateCoreDataForCar(car: car, month: date, amount: amount)
                        }
                    } else {
                        //Triggers if the device doesn't have the point
                        print("Adding odometer point")
                        DispatchQueue.main.async {
                            self.carData[car]![date] = amount
                            self.addPointToCoreData(car: car, month: date, point: amount)
                        }
                    }
                } else {
                    //Triggers if the device doesn't have the car
                    print("Adding car")
                    DispatchQueue.main.sync {
                        self.carData[car] = [date:amount]
                        self.addPointToCoreData(car: car, month: date, point: amount)
                    }
                }
            }
            
            upload(uploadedPoints)
            
            self.compileToGraph()
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                upload(nil)
            }
        })
    }
}
