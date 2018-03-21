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
    var carData:[String:[GreenDataPoint]]
    var carMileage:[String:GreenAttribute]

    init() {
        let defaults = UserDefaults.standard
        
        carData = [:]
        
        if let json = defaults.string(forKey: "MilesData") {
            let mileages = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            carMileage = mileages!
        } else {
            carMileage = [:]
            if let mileages = defaults.dictionary(forKey: "MilesData") as? [String:Int] {
                for (key, value) in mileages {
                    carMileage[key] = GreenAttribute(value: value, lastUpdated: Date())
                }
            }
        }
        
        //https://www.epa.gov/sites/production/files/2016-02/documents/420f14040a.pdf
        //4.7 metric tons/12 = 390 kg
        //The equivalent is 950 miles
        super.init(name: GreenDataType.driving.rawValue, xLabel: "Month", yLabel: "Miles", base: 950, averageLabel: "Miles per Day", icon: Icon.road_emblem)
        
        self.calculateCO2 = {
            miles in
            return 19.6*miles/Double(self.data["Average MPG"]!.value)
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
                    
                    let dataPoint = GreenDataPoint(month: month, value: amount, dataType: dataName, pointType: .odometer)
                    if let lastUpdated = managedObj.value(forKeyPath: "lastUpdated") as? Date {
                        dataPoint.lastUpdated = lastUpdated
                    }
                    
                    if let _ = carData[name] {
                        carData[name]!.append(dataPoint)
                    } else {
                        carData[name] = [dataPoint]
                    }
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    func compileToGraph() {
        var totalMPG = 0
        for (key, point) in carMileage {
            if carData[key] != nil && carData[key]!.count != 0 {
                totalMPG += point.value
            }
        }
        
        if totalMPG == 0 || carMileage.count == 0 {
            self.data["Average MPG"] = GreenAttribute(value: 0, lastUpdated: Date())
            self.data["Number of Cars"] = GreenAttribute(value: 0, lastUpdated: Date())
            return
        }
        
        self.data["Average MPG"] = GreenAttribute(value: totalMPG/carMileage.count, lastUpdated: Date())
        self.data["Number of Cars"] = GreenAttribute(value: carMileage.count, lastUpdated: Date())
        
        let odometerArr:[[GreenDataPoint]] = Array(carData.values)
        
        var dataDict:[[Date:Int]] = []
        //Splits the data so non-consecutive months are split into consecutive ones
        for carReadings in odometerArr {
            var data:[Date:Int] = [:]
            for index in 0..<carReadings.count-1 {
                let firstMonth = carReadings[index].month
                let secondMonth = carReadings[index+1].month
                
                let difference = carReadings[index+1].value - carReadings[index].value
                
                let monthDiff = secondMonth.months(from: firstMonth)
                let bucketNum = Int(difference)/monthDiff
                data[firstMonth] = bucketNum
                var nextMonth = firstMonth.nextMonth()
                
                while secondMonth.compare(nextMonth) != ComparisonResult.orderedSame {
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
            
            let index = indexOfPointForDate(date, inArray: graphData)
            if index == -1 {
                let dataPoint = GreenDataPoint(month: date, value: miles, dataType: self.dataName)
                addDataPoint(point: dataPoint, save:true)
            } else {
                editDataPoint(atIndex: index, toValue: miles)
            }
        }
        
        for i in 0..<graphData.count {
            if !keys.contains(graphData[i].month) {
                removeDataPoint(atIndex: i)
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
                    fetchedEntities.first?.setValue(Date(), forKeyPath: "lastUpdated")
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
                let lastUpdated = pointInfo["LastUpdated"]! as! Double
                let car = dataType.components(separatedBy: ":")[2]
                
                uploadedCars.append(car)
                
                if let savedMileage = self.carMileage[car] {
                    if savedMileage.value != mileage && savedMileage.lastUpdated.timeIntervalSince1970 < lastUpdated {
                        print("Editing car mileage")
                        self.carMileage[car] = GreenAttribute(value: mileage, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                    }
                } else {
                    self.carMileage[car] = GreenAttribute(value: mileage, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                }
            }
            
            for (car, mileage) in self.carMileage {
                if !uploadedCars.contains(car) {
                    sendToServer(car, mileage.value)
                }
            }
            
            self.pointConsensus()
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                for (car, mileage) in self.carMileage {
                    sendToServer(car, mileage.value)
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
                    for odometerReading in self.carData[car]! {
                        let date = Date.monthFormat(date: odometerReading.month)
                        let id = [car, date].joined(separator:":")
                        if !uploadedPoints!.contains(id) {
                            print("Found unuploaded odometer point")
                            
                            sendToServer(car, odometerReading.month, odometerReading.value)
                        }
                    }
                }
            } else {
                for car in self.carData.keys {
                    for odometerReading in self.carData[car]! {
                        print("Found unuploaded odometer point")
                        sendToServer(car, odometerReading.month, odometerReading.value)
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
                let lastUpdated = pointInfo["LastUpdated"]! as! Double
                
                let car = dataType.components(separatedBy: ":")[2]
                let date = formatter.date(from: month)!
                
                uploadedPoints.append(car+":"+month)
                
                if let savedPoints = self.carData[car] {
                    let index = self.indexOfPointForDate(date, inArray: savedPoints)
                    if index != -1 {
                        let point = savedPoints[index]
                        if point.value != amount && point.lastUpdated.timeIntervalSince1970 < lastUpdated  {
                            //Triggers if the device has the point saved but is an outdated value
                            print("Editing odometer point")
                            self.carData[car]![index].value = amount
                            self.carData[car]![index].lastUpdated = Date(timeIntervalSince1970: lastUpdated)
                            self.updateCoreDataForCar(car: car, month: date, amount: amount)
                        }
                    } else {
                        print("Adding odometer point")
                        let odometerReading = GreenDataPoint(month: date, value: amount, dataType: self.dataName, pointType:.odometer, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                        DispatchQueue.main.async {
                            self.carData[car]!.append(odometerReading)
                            self.addPointToCoreData(car: car, month: date, point: amount)
                        }
                    }
                } else {
                    //Triggers if the device doesn't have the car
                    print("Adding car")
                    DispatchQueue.main.sync {
                        let odometerReading = GreenDataPoint(month: date, value: amount, dataType: self.dataName, pointType:.odometer, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                        self.carData[car] = [odometerReading]
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
