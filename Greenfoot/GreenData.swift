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
    var bonus: (Int, Int) -> Int
    
    private var graphData:[Date: Double]
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
        energyPoints = 0
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
    }
    
    func addDataPoint(month:Date, y:Double, save: Bool) {
        graphData[month] = y
        energyPoints += calculateEP(baseline, y)
        
        if save {
            CoreDataHelper.save(data: self, month: month, amount: y)
        }
    }
    
    func getGraphData() -> [Date: Double] {
        return graphData
    }
    
    func editDataPoint(month:Date, y:Double) {
        graphData[month] = y
        recalculateEP()
    }
    
    func removeDataPoint(month:Date) {
        graphData.removeValue(forKey: month)
        recalculateEP()
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
    
    func addToServer(month:String, point:Double) {
        let modal = GreenfootModal.sharedInstance
        guard let locality = modal.locality else {
            return
        }
        let base = URL(string: "http://localhost:8000")!
        //let base = URL(string: "http://ec2-13-58-235-219.us-east-2.compute.amazonaws.com:8000")!
        let url = URL(string: "input", relativeTo: base)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        
        let bodyData = "profId=\(modal.profId)&dataType=\(dataName)&month=\(month)&amount=\(Int(point))&city=\(locality["City"]!)&state=\(locality["State"]!)&country=\(locality["Country"]!)"
        request.httpBody = bodyData.data(using: String.Encoding.utf8)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) in
            
            if error != nil {
                guard let description = error? .localizedDescription else {
                    return
                }
                print(description)
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
                
                print(retVal!)
                if retVal!["status"] as! String == "Success" {
                    self.uploadedData.append(month)
                    CoreDataHelper.update(data: self, month: Date.monthFormat(date: month), updatedValue: point, uploaded: true)
                }
            } catch _ {
                print("Failed decoding JSON")
            }
        })
        task.resume()
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
        
        if let odometerData = defaults.dictionary(forKey: "CarData") as? [String:[String:Int]] {
            carData = odometerData
        } else {
            carData = [:]
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
    
    func save(defaults: UserDefaults) {
        defaults.set(carMileage, forKey: "MilesData")
        defaults.set(carData, forKey: "CarData")
    }
    
    func compileToGraph() {
        var totalMPG = 0
        for (_, value) in carMileage {
            totalMPG += value
        }
        
        if totalMPG == 0 || carMileage.count == 0 {
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
            let d1 = Date.monthFormat(date: date1)
            let d2 = Date.monthFormat(date: date2)
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
        for i in 0..<keys.count-1 {
            let firstKey = keys[i]
            let nextKey = keys[i+1]
            differences[firstKey] = sums[nextKey]!-sums[firstKey]!
        }
        
        for (key, value) in differences {
            let date = Date.monthFormat(date: key)
            let co2 = co2Emissions(Double(value), self.data["Average MPG"]!)
            if let _ = getGraphData()[date] {
                editDataPoint(month: date, y: co2)
            } else {
                addDataPoint(month: date, y: co2, save:false)
            }
        }
    }
}
