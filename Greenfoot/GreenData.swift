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
    
    var attributes: [String]
    var descriptions: [String]
    
    var averageLabel:String
    var icon:UIImage
    
    var calculateEP: (Double, Double) -> Int
    var calculateCO2: (Double) -> Double
    var bonus: (Int, Int) -> Int
    
    private var graphData:[Date: Double]
    private var epData:[Date: Int]
    private var co2Equivalent:[Date: Double]
    
    var uploadedData:[String]
    
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
    
    var xLabel:String
    var yLabel:String
    
    var energyPoints:Int
    var totalCarbon: Int
    
    var baseline:Double
    
    init(name:String, xLabel:String, yLabel:String, base: Double, averageLabel:String, icon:UIImage) {
        self.xLabel = xLabel
        self.yLabel = yLabel
        data = [:]
        baselines = [:]
        bonusDict = [:]
        
        attributes = []
        descriptions = []
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
        
        self.calculateEP = {
            base, point in
            let diff = base - point
            if diff < 0 {
                return Int(-1*pow(-5 * diff, 1.0/3.0))
            } else {
                return Int(pow(5 * diff, 1.0/3.0))
            }
        }
        
        bonus = {
            base, attr in
            return (attr > base) ? 5*(attr-base) : 0
        }
        
        calculateCO2 = {
            point in
            return point
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
    
    private func recalculateCarbon() {
        totalCarbon = 0
        for (key, value) in graphData {
            let carbon = calculateCO2(value)
            
            totalCarbon += Int(carbon)
            co2Equivalent[key] = carbon
            
        }
    }
    
    func fetchEGrid() {
        if dataName != "Electric" {
            return
        }
        
        guard let locality = GreenfootModal.sharedInstance.locality else {
            return
        }
        
        let parameters:[String:String] = ["zip":locality["Zip"]!]
        connectToServer(atEndpoint: "getFromEGrid", withParameters: parameters, completion: {
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
        
        connectToServer(atEndpoint: "input", withParameters: parameters, completion: {
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
        
        connectToServer(atEndpoint: "updateDataPoint", withParameters: parameters, completion: {
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

        connectToServer(atEndpoint: "deleteDataPoint", withParameters: parameters, completion: {
            data in
                
            if data["status"] as! String == "Success" {
                print("Successfully deleted from server")
            } else {
                print("Couldn't delete from server")
            }
        })
    }
    
    fileprivate func connectToServer(atEndpoint endpoint:String, withParameters parameters:[String:Any], completion: @escaping (NSDictionary) -> Void) {
        let base = URL(string: "http://192.168.1.78:8000")!
        //let base = URL(string: "http://ec2-13-58-235-219.us-east-2.compute.amazonaws.com:8000")!
        let url = URL(string: endpoint, relativeTo: base)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        
        let bodyData = bodyFromParameters(parameters: parameters)
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                guard let description = error? .localizedDescription else {
                    completion(["status":"Failed", "message":"Unknown error found"])
                    return
                }
                print(description)
                completion(["status":"Failed", "message":description])
                return
            }
            
            if let HTTPResponse = response as? HTTPURLResponse {
                let statusCode = HTTPResponse.statusCode
                if statusCode != 200 {
                    print("Couldn't connect error because status not 200 its \(statusCode)")
                }
            }
            
            do  {
                let retVal = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                completion(retVal!)
            } catch _ {
                completion(["status":"Failed", "message":"Could not decode JSON"])
            }
        })
        task.resume()
    }
    
    private func bodyFromParameters(parameters:[String:Any]) -> String {
        var bodyData = ""
        for (key, value) in parameters {
            bodyData.append(key+"=\(value)&")
        }
        bodyData.remove(at: bodyData.index(before: bodyData.endIndex))
        return bodyData
    }
}

class EmissionsData: GreenData {
    var carData:[String:[String:Int]]
    var carMileage:[String:Int]
    
    let co2Emissions:(Double, Int) -> Double = {
        miles, mpg in
        return 8.887*miles/Double(mpg)
    }
    
    init() {
        let defaults = UserDefaults.standard
        
        carData = [:]
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Car")
            
            do {
                let managedObjects = try managedContext.fetch(fetchRequest)
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/yy"
                for managedObj in managedObjects {
                    let name = managedObj.value(forKeyPath: "name") as! String
                    let amount = managedObj.value(forKeyPath: "amount") as! Int
                    let month = managedObj.value(forKeyPath: "month") as! String
                    
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
        super.init(name: "Emissions", xLabel: "Month", yLabel: "kg", base: 390, averageLabel: "Kilograms per Day", icon: Icon.smoke_white)
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
        
        var dictArr:[[String:Int]] = []
        for key in carData.keys {
            dictArr.append(carData[key]!)
        }
        var keys:[String] = []
        for dict in dictArr {
            for key in dict.keys {
                if !keys.contains(key) {
                    keys.append(key)
                }
            }
        }
        keys.sort(by: {
            (date1, date2) in
            let d1 = Date.monthFormat(string: date1)
            let d2 = Date.monthFormat(string: date2)
            return d1.compare(d2) == ComparisonResult.orderedAscending
        })
        
        var sums:[String:Int] = [:]
        for i in 0..<keys.count {
            let key = keys[i]
            var sum = 0
            for dict in dictArr {
                if let val = dict[key] {
                    sum += val
                }
            }
            sums[key] = sum
        }
        
        var differences:[String:Int] = [:]
        if keys.count-1 < 0 {
            return
        }
        for i in 0..<keys.count-1 {
            let firstKey = keys[i]
            let nextKey = keys[i+1]
            differences[firstKey] = sums[nextKey]!-sums[firstKey]!
        }
        
        for (key, value) in differences {
            let date = Date.monthFormat(string: key)
            let co2 = co2Emissions(Double(value), self.data["Average MPG"]!)
            if let _ = getGraphData()[date] {
                editDataPoint(month: date, y: co2)
            } else {
                addDataPoint(month: date, y: co2, save:true)
            }
        }
    }
    
    func addPointToCoreData(car:String, month: String, point: Int16) {
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
    }
    
    func deletePointForCar(_ car:String, month:String) {
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
    
    func updateCoreDataForCar(car: String, month: String, amount: Int16) {
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
