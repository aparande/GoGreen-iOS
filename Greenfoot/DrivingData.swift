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
        
        if let json = defaults.data(forKey: "MilesData") {
            let mileages = try? JSONDecoder().decode([String:GreenAttribute].self, from: json)
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
            
            let co2 = 19.6*miles/Double(self.data["Average MPG"]!.value)
            
            return (co2.isNaN || co2.isInfinite) ? 0 : co2
        }
        
        self.calculateEP = {
            base, point in
            let diff = (self.calculateCO2(base) - self.calculateCO2(point))/100
            
            return (diff.isNaN || diff.isInfinite) ? 0 : Int(floor(diff))
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
                    
                    if let isDeleted = managedObj.value(forKeyPath: "hasBeenDeleted") as? Bool {
                        dataPoint.isDeleted = isDeleted
                    }
                    
                    if !dataPoint.isDeleted {
                        if let _ = carData[name] {
                            carData[name]!.append(dataPoint)
                        } else {
                            carData[name] = [dataPoint]
                        }
                    }
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }
    
    func compileToGraph() {
        var totalMPG = 0
        var carCount = 0
        for (key, point) in carMileage {
            if carData[key] != nil && carData[key]!.count != 0 && !point.isDeleted {
                totalMPG += point.value
                carCount += 1
            }
        }
        
        if totalMPG == 0 || carMileage.count == 0 {
            self.data["Average MPG"] = GreenAttribute(value: 0, lastUpdated: Date())
            self.data["Number of Cars"] = GreenAttribute(value: 0, lastUpdated: Date())
            
            for (key, attribute) in self.data {
                var parameters:[String:Any] = ["month":"NA", "amount":attribute.value, "lastUpdated": attribute.lastUpdated.timeIntervalSince1970]
                parameters["dataType"] = [self.dataName, "Data", key].joined(separator: ":")
                let id=[APIRequestType.log.rawValue, self.dataName, key].joined(separator: ":")
                self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
            }
            
            for var i in 0..<graphData.count {
                //Include the graphData.count condition to stop index out of range errors.
                if i < graphData.count {
                    removeDataPoint(atIndex: i, fromServer: true)
                    i -= 1
                }
            }
            
            return
        }
        
        let oldMPG = self.data["Average MPG"]!.value
        let oldCarCount = self.data["Number of Cars"]!.value
        let newMPG = totalMPG/carCount
        
        //Update on the server and the device if the car counts changed
        if oldMPG != newMPG || oldCarCount != carCount {
            
            let averageMPG = GreenAttribute(value: totalMPG/carCount, lastUpdated: Date()) //Use carCount instead of carMileage.count for these two calculations because of deleted cars on the device which haven't been uploaded to the server yet
            let carCountPoint = GreenAttribute(value: carCount, lastUpdated: Date())
            
            self.data["Average MPG"] = averageMPG
            self.data["Number of Cars"] = carCountPoint
            
            for (key, attribute) in self.data {
                var parameters:[String:Any] = ["month":"NA", "amount":attribute.value, "lastUpdated": attribute.lastUpdated.timeIntervalSince1970]
                parameters["dataType"] = [self.dataName, "Data", key].joined(separator: ":")
                let id=[APIRequestType.log.rawValue, self.dataName, key].joined(separator: ":")
                self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
            }
        }
        
        
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
                addDataPoint(point: dataPoint, save:true, upload: true)
            } else {
                editDataPoint(atIndex: index, toValue: miles)
            }
        }
        
        for var i in 0..<graphData.count {
            //Include the graphData.count condition and the i -= 1 to stop index out of range errors.
            if i < graphData.count && !keys.contains(graphData[i].month) {
                removeDataPoint(atIndex: i, fromServer: true)
                i -= 1
            }
        }
        
        let notification = NSNotification.Name.init(rawValue: "compiledCarData")
        NotificationCenter.default.post(name: notification, object: self)
    }
    
    func addOdometerReading(_ reading: GreenDataPoint, forCar car:String) {
        self.carData[car]!.append(reading)
        CoreDataHelper.addOdometerReading(reading, forCar: car)
        
        let dateString = Date.monthFormat(date:reading.month)
        
        var parameters:[String:Any] = ["month": dateString, "amount":Int(reading.value), "lastUpdated": reading.lastUpdated.timeIntervalSince1970]
        parameters["dataType"] = self.dataName+":Point:"+car
        let id=[APIRequestType.log.rawValue, self.dataName, car, dateString].joined(separator: ":")
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
    }
    
    func addCarToServer(_ car:String, describedByPoint point:GreenAttribute) {
        var parameters:[String:Any] = ["month":"NA", "amount":point.value, "lastUpdated": point.lastUpdated.timeIntervalSince1970]
        parameters["dataType"] = [self.dataName, "Car", car].joined(separator: ":")
        let id=[APIRequestType.log.rawValue, self.dataName, car].joined(separator: ":")
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
    }
    
    func deleteCar(_ car:String, fromServer shouldDeleteFromServer: Bool) {
        //Mark the mileage point for the car as deleted
        carMileage[car]!.delete() //Don't remove it from the dictionary immediately because it might not connect to the server
        let encodedData = try? JSONEncoder().encode(self.carMileage)
        UserDefaults.standard.set(encodedData, forKey: "MilesData")
        
        carData.removeValue(forKey: car) //We can remove the array instead of marking points as deleted since they'll be marked as deleted in Core Data
        
        let saveDataGroup = DispatchGroup()
        saveDataGroup.enter()
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let predicate = NSPredicate(format: "name == %@", argumentArray: [car])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                for entry in fetchedEntities {
                    if shouldDeleteFromServer {
                        let name = entry.value(forKeyPath: "name") as! String
                        let month = entry.value(forKeyPath: "month") as! Date
                        
                        let dateString = Date.monthFormat(date:month)
                        var parameters:[String:Any] = ["month":dateString]
                        parameters["dataType"] = dataName+":Point:"+name
                        let id=[APIRequestType.delete.rawValue, dataName, name, dateString].joined(separator: ":")
                        
                        //If the call to the server is successful, delete the point. Otherwise, simply update the point for deletion later
                        saveDataGroup.enter()
                        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withSuccessFunction: {
                            _ in
                            print ("Successfully deleted odometer reading")
                            managedContext.delete(entry)
                            saveDataGroup.leave()
                        }, andFailureFunction: {
                            _ in
                            entry.setValue(true, forKeyPath: "hasBeenDeleted")
                            saveDataGroup.leave()
                        })
                        
                    } else {
                        managedContext.delete(entry)
                    }
                    
                }
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
            saveDataGroup.leave()
            saveDataGroup.notify(queue: .main) {
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
        
        if shouldDeleteFromServer {
            deleteMileage(forCar: car)
        }
        
        compileToGraph()
        recalculateEP()
        recalculateCarbon()
    }
    
    func updateOdometerReading(forCar car: String, atIndex index: Int, toValue value:Double) {
        carData[car]?[index].value = value
        carData[car]?[index].lastUpdated = Date()
        let point: GreenDataPoint = carData[car]![index]
        
        //Set server call parameters
        let dateString = Date.monthFormat(date:point.month)
        var parameters:[String:Any] = ["month": dateString, "amount":Int(point.value), "lastUpdated": point.lastUpdated.timeIntervalSince1970]
        parameters["dataType"] = dataName+":Point:"+car
        let id=[APIRequestType.log.rawValue, dataName, car, dateString].joined(separator: ":")
        
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
        CoreDataHelper.updateOdometerReading(point, forCar: car)
    }
    
    func deleteOdometerReading(_ point: GreenDataPoint, forCar car:String) {
        //Set server call parameters
        let dateString = Date.monthFormat(date:point.month)
        var parameters:[String:Any] = ["month":dateString]
        parameters["dataType"] = dataName+":Point:"+car
        let id=[APIRequestType.delete.rawValue, dataName, car, dateString].joined(separator: ":")
        
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withSuccessFunction: {
            (success) in
            //If the server sucessfully marks the point as deleted, then there is no reason to keep it saved on the device
            print("Yay server marked it")
            CoreDataHelper.deleteOdometerReading(point, forCar: car)
        }, andFailureFunction: {
            errorDict in
            //If the server does not mark the point as deleted, mark it as deleted on the device
            print ("Rip no server")
            point.isDeleted = true
            CoreDataHelper.updateOdometerReading(point, forCar: car)
        })
    }
    
    private func deleteMileage(forCar car: String) {
        var parameters:[String:Any] = ["month":"NA"]
        parameters["dataType"] = dataName+":Car:"+car
        let id=[APIRequestType.delete.rawValue, dataName, car].joined(separator: ":")
        self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "deleteDataPoint", withSuccessFunction: {
            _ in
            //Remove the mileage value from the device since it has been deleted from the server
            self.carMileage.removeValue(forKey: car)
            let encodedData = try? JSONEncoder().encode(self.carMileage)
            UserDefaults.standard.set(encodedData, forKey: "MilesData")
        }, andFailureFunction: {
            _ in
            print("Error deleting mileage for Car named \(car)")
        })
    }
    
    override func reachConsensus() {
        consensusFor("Bonus", completion:nil)
        consensusFor("Data", completion: {
            success in
            
            if success {
                self.carConsensus()
            } else {
                self.compileToGraph()
            }
        })
    }
    
    private func carConsensus() {
        let id = [APIRequestType.consensus.rawValue, dataName, "Cars"].joined(separator: ":")
        let dataType = dataName
        let parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "dataType": dataType, "assoc": "Car"]
        
        let sendToServer:(String, Int, Date) -> Void = {
            car, mileage, lastUpdated in
            var parameters:[String:Any] = ["month":"NA", "amount":mileage, "lastUpdated": lastUpdated.timeIntervalSince1970]
            parameters["dataType"] = [self.dataName, "Car", car].joined(separator: ":")
            let id=[APIRequestType.log.rawValue, self.dataName, car].joined(separator: ":")
            self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
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
                let isDeleted = pointInfo["IsDeleted"]! as! Double
                
                //If the car is not deleted, then check to see if there are points containing that car and update accordingly
                if isDeleted == 0 {
                    //If we have a car with the same name already, check to see if it is not out of date.
                    //If it is more updated than the server, then don't put it in uploaded cars so it gets sent to the server
                    if let savedMileage = self.carMileage[car] {
                        if savedMileage.isDeleted {
                            uploadedCars.append(car)
                            self.deleteMileage(forCar: car)
                        } else if savedMileage.value != mileage && savedMileage.lastUpdated.timeIntervalSince1970 < lastUpdated {
                            print("Editing car mileage")
                            self.carMileage[car] = GreenAttribute(value: mileage, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                            uploadedCars.append(car)
                        }
                    } else {
                        self.carMileage[car] = GreenAttribute(value: mileage, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                        uploadedCars.append(car)
                    }
                } else {
                    //If the car is deleted, make sure it is removed from the device if it is still on the device
                    uploadedCars.append(car)
                    if let _ = self.carMileage[car] {
                        DispatchQueue.main.async {
                            self.deleteCar(car, fromServer: false)
                        }
                    }
                }
            }
            
            for (car, mileage) in self.carMileage {
                if !uploadedCars.contains(car) {
                    sendToServer(car, mileage.value, mileage.lastUpdated)
                }
            }
            
            self.pointConsensus()
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                for (car, mileage) in self.carMileage {
                    sendToServer(car, mileage.value, mileage.lastUpdated)
                }
            }
            
            self.pointConsensus()
        })
    }
    
    override func pointConsensus() {
        let upload:([String]?) -> Void = {
            uploadedPoints in
            
            let sendToServer:(String, Date, Double, Date) -> Void = {
                car, month, amount, lastUpdated in
                let dateString = Date.monthFormat(date:month)
                var parameters:[String:Any] = ["month": dateString, "amount":Int(amount), "lastUpdated": lastUpdated.timeIntervalSince1970]
                parameters["dataType"] = self.dataName+":Point:"+car
                let id=[APIRequestType.log.rawValue, self.dataName, car, dateString].joined(separator: ":")
                self.makeServerCall(withParameters: parameters, identifiedBy: id, atEndpoint: "logData", containingLocation: true)
            }
            
            if let _ = uploadedPoints {
                for car in self.carData.keys {
                    for odometerReading in self.carData[car]! {
                        let date = Date.monthFormat(date: odometerReading.month)
                        let id = [car, date].joined(separator:":")
                        if !uploadedPoints!.contains(id) {
                            print("Found unuploaded odometer point")
                            
                            sendToServer(car, odometerReading.month, odometerReading.value, odometerReading.lastUpdated)
                        }
                    }
                }
            } else {
                for car in self.carData.keys {
                    for odometerReading in self.carData[car]! {
                        print("Found unuploaded odometer point")
                        sendToServer(car, odometerReading.month, odometerReading.value, odometerReading.lastUpdated)
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
                let isDeleted = pointInfo["IsDeleted"]! as! Double
                
                let car = dataType.components(separatedBy: ":")[2]
                let date = formatter.date(from: month)!
                
                uploadedPoints.append(car+":"+month)
                
                if let savedPoints = self.carData[car] {
                    let index = self.indexOfPointForDate(date, inArray: savedPoints)
                    if index != -1 {
                        //The device has the point saved (it is not deleted)
                        if isDeleted == 0 {
                            let point = savedPoints[index]
                            if point.value != amount && point.lastUpdated.timeIntervalSince1970 < lastUpdated  {
                                //Outdated value
                                print("Editing odometer point")
                                self.carData[car]![index].value = amount
                                self.carData[car]![index].lastUpdated = Date(timeIntervalSince1970: lastUpdated)
                                CoreDataHelper.updateOdometerReading(self.carData[car]![index], forCar: car)
                            }
                        } else {
                            //The device has the point saved but the server deleted it, so delete it from CoreData
                            let point = savedPoints[index]
                            DispatchQueue.main.async {
                                CoreDataHelper.deleteOdometerReading(point, forCar: car)
                            }
                        }
                    } else {
                        //The device does not have the point saved. Check to see if the server has deleted it before adding it
                        if isDeleted == 0 {
                            CoreDataHelper.hasDeletedOdometerReading(date, forCar: car, callback: {
                                deletedPoint in
                                
                                if let _ = deletedPoint {
                                    //The device has deleted this point, so delete it from the server
                                    self.deleteOdometerReading(deletedPoint!, forCar: car)
                                } else {
                                    //The device has not deleted this point, so add it
                                    print("Adding odometer point")
                                    let odometerReading = GreenDataPoint(month: date, value: amount, dataType: self.dataName, pointType:.odometer, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                                    self.carData[car]!.append(odometerReading)
                                    DispatchQueue.main.async {
                                        CoreDataHelper.addOdometerReading(odometerReading, forCar: car)
                                    }
                                }
                            })
                        }
                    }
                } else {
                    //Triggers if the device doesn't have the car and the car is not deleted on the server
                    if isDeleted == 0 {
                        CoreDataHelper.hasDeletedOdometerReading(date, forCar: car, callback: {
                            deletedPoint in
                            
                            if let _ = deletedPoint {
                                //The device has deleted this point, so delete it from the server
                                self.deleteOdometerReading(deletedPoint!, forCar: car)
                            } else {
                                //The device has not deleted this point, so add it
                                print("Adding odometer point")
                                let odometerReading = GreenDataPoint(month: date, value: amount, dataType: self.dataName, pointType:.odometer, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
                                self.carData[car] = [odometerReading]
                                DispatchQueue.main.async {
                                    CoreDataHelper.addOdometerReading(odometerReading, forCar: car)
                                }
                            }
                        })
                    }
                }
            }
            
            upload(uploadedPoints)
            
            for (car, _) in self.carData {
                self.carData[car]!.sort(by: {
                    (point1, point2) in
                    return point1.month.compare(point2.month) == ComparisonResult.orderedAscending
                })
            }
            
            self.compileToGraph()
            
        }, andFailureFunction: {
            errorDict in
            
            if errorDict["Error"] as? APIError == .serverFailure {
                upload(nil)
            }
            
            self.compileToGraph()
        })
    }
}
