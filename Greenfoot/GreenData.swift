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
    
    fileprivate var graphData:[Date: Double]
    fileprivate var epData:[Date: Int]
    fileprivate var co2Equivalent:[Date: Double]
    
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
        
        //Mark the point as unuploaded in the database always
        CoreDataHelper.update(data: self, month: month, updatedValue: y, uploaded: false)
        //If the data is uploaded, update it, else, uploade it
        let date = Date.monthFormat(date: month)
        if let index = uploadedData.index(of: date) {
            uploadedData.remove(at: index)
            updateOnServer(month: date, point: y)
        } else {
            addToServer(month: date, point: y)
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
    
    fileprivate func recalculateCarbon() {
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
        let api = APIInterface()
        api.connectToServer(atEndpoint: "getFromEGrid", withParameters: parameters, completion: {
            data in
            
            if data["status"] as! String == "Success" {
                let e_factor = data["e_factor"] as! Double
                UserDefaults.standard.set(e_factor, forKey: "e_factor")
                
                self.calculateCO2 = {
                    point in
                    return point * e_factor/1000
                }
                
                self.recalculateCarbon()
            } else {
                print("Failed to load electric grid because: "+(data["message"] as! String))
            }
        })
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
        let api = APIInterface()
        api.connectToServer(atEndpoint: "/getFromConsumption", withParameters: parameters, completion: {
            data in
            
            if data["status"] as! String == "Success" {
                let consumption = data["value"] as! Double
                self.stateConsumption = consumption
                print("State consumption is \(self.stateConsumption!)")
            } else {
                print("Failed to load consumption because: "+(data["message"] as! String))
            }
        })
    }
    
    func addToServer(month:String, point:Double) {
        //This is the check to see if the user wants to share their data
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month, "amount":Int(point)]
        parameters["profId"] = GreenfootModal.sharedInstance.profId
        parameters["dataType"] = dataName
        
        parameters["city"] = locality["City"]!
        parameters["state"] = locality["State"]
        parameters["country"] = locality["Country"]
        
        let api = APIInterface()
        api.connectToServer(atEndpoint: "input", withParameters: parameters, completion: {
            data in
            if data["status"] as! String == "Success" {
                self.uploadedData.append(month)
                CoreDataHelper.update(data: self, month: Date.monthFormat(string: month), updatedValue: point, uploaded: true)
            }
        })
    }
    
    fileprivate func updateOnServer(month:String, point: Double) {
        //This is the check to see if the user wants to share their data
        guard let _ = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month, "amount":Int(point)]
        parameters["profId"] = GreenfootModal.sharedInstance.profId
        parameters["dataType"] = dataName
        let api = APIInterface()
        api.connectToServer(atEndpoint: "updateDataPoint", withParameters: parameters, completion: {
            data in
            if data["status"] as! String == "Success" {
                self.uploadedData.append(month)
                CoreDataHelper.update(data: self, month: Date.monthFormat(string: month), updatedValue: point, uploaded: true)
            }
        })
    }
    
    fileprivate func deleteFromServer(month: String) {
        //This is the check to see if the user wants to share their data
        guard let _ = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        var parameters:[String:Any] = ["month":month]
        parameters["profId"] = GreenfootModal.sharedInstance.profId
        parameters["dataType"] = dataName

        let api = APIInterface()
        api.connectToServer(atEndpoint: "deleteDataPoint", withParameters: parameters, completion: {
            data in
                
            if data["status"] as! String == "Success" {
                print("Successfully deleted from server")
            } else {
                print("Couldn't delete from server")
            }
        })
    }
}

class DrivingData: GreenData {
    var carData:[String:[Date:Double]]
    var carMileage:[String:Int]
    
    let co2Emissions:(Double, Int) -> Double = {
        miles, mpg in
        return 19.6*miles/Double(mpg)
    }
    
    init() {
        let defaults = UserDefaults.standard
        
        carData = [:]
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
        
        if let mileages = defaults.dictionary(forKey: "MilesData") as? [String:Int] {
            carMileage = mileages
        } else {
            carMileage = [:]
        }
        
        //https://www.epa.gov/sites/production/files/2016-02/documents/420f14040a.pdf
        //4.7 metric tons/12 = 390 kg
        //The equivalent is 950 miles
        super.init(name: GreenDataType.driving.rawValue, xLabel: "Month", yLabel: "Miles", base: 950, averageLabel: "Miles per Day", icon: Icon.road_white)
        
        self.calculateEP = {
            base, point in
            let diff = (self.co2Emissions(base, self.data["Average MPG"]!) - self.co2Emissions(point, self.data["Average MPG"]!))/100

            return Int(floor(diff))
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
            if let _ = getGraphData()[date] {
                editDataPoint(month: date, y: miles)
            } else {
                addDataPoint(month: date, y: miles, save:true)
            }
        }
    }
    
    override func addDataPoint(month:Date, y:Double, save: Bool) {
        graphData[month] = y
        
        let ep = calculateEP(baseline, y)
        epData[month] = ep
        energyPoints += ep
        
        let carbon = co2Emissions(y, self.data["Average MPG"]!)
        co2Equivalent[month] = carbon
        totalCarbon += Int(carbon)
        
        if save {
            CoreDataHelper.save(data: self, month: month, amount: y)
            
            //If save is true, that means its a new data point, so you want to try uploading to the server
            addToServer(month: Date.monthFormat(date: month), point: y)
        }
    }
    
    override func editDataPoint(month:Date, y:Double) {
        let epPrev = epData[month]!
        let carbonPrev = co2Equivalent[month]!
        
        graphData[month] = y
        
        let ep = calculateEP(baseline, y)
        epData[month] = ep
        energyPoints = energyPoints - epPrev + ep
        
        let carbon = co2Emissions(y, self.data["Average MPG"]!)
        co2Equivalent[month] = carbon
        totalCarbon = totalCarbon - Int(carbonPrev) + Int(carbon)
        
        //Mark the point as unuploaded in the database always
        CoreDataHelper.update(data: self, month: month, updatedValue: y, uploaded: false)
        //If the data is uploaded, update it, else, uploade it
        let date = Date.monthFormat(date: month)
        if let index = uploadedData.index(of: date) {
            uploadedData.remove(at: index)
            updateOnServer(month: date, point: y)
        } else {
            addToServer(month: date, point: y)
        }
    }
    
    func addPointToCoreData(car:String, month: Date, point: Double) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: managedContext)!
            
            let obj = NSManagedObject(entity: entity, insertInto: managedContext)
            
            obj.setValue(car, forKeyPath: "name")
            obj.setValue(month, forKeyPath: "month")
            obj.setValue(point, forKeyPath: "amount")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
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
        
        if carData.keys.count == 0 {
            graphData = [:]
            epData = [:]
            co2Equivalent = [:]
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
            let predicate = NSPredicate(format: "name == %@ and month == %@", argumentArray: [car, month])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                for entry in fetchedEntities {
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
    }
    
    func updateCoreDataForCar(car: String, month: Date, amount: Double) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let predicate = NSPredicate(format: "name == %@ AND month == %@", argumentArray: [car, month])
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Car")
            fetchRequest.predicate = predicate
            
            let managedContext = appDelegate.persistentContainer.viewContext
            do {
                let fetchedEntities = try managedContext.fetch(fetchRequest)
                fetchedEntities.first?.setValue(amount, forKeyPath: "amount")
            } catch let error as NSError {
                print("Could not update. \(error), \(error.userInfo)")
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
}
