//
//  GreenfootModal.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/29/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit
import Material

class GreenfootModal {
    static let sharedInstance = GreenfootModal()
    
    var data:[String:GreenData]
    
    var totalEnergyPoints:Int {
        get {
            var sum = 0
            for (_, value) in data {
                sum += value.energyPoints
            }
            
            return sum
        }
    }
    
    var totalCarbon: Int {
        get {
            var sum = 0
            for (_, value) in data {
                sum += value.totalCarbon
            }
            return sum
        }
    }
    
    var locality:[String:String]?
    let profId:String
    var rankings:[String:Int]
    
    private var rankingFetchInProgress: Bool
    
    init() {
        data = [:]
        rankings = [:]
        
        let defaults = UserDefaults.standard
        
        if let uuid = defaults.string(forKey: "ProfId") {
            profId = uuid
        } else {
            profId = UUID().uuidString
            defaults.set(profId, forKey: "ProfId")
        }
        
        if let locale_data = defaults.dictionary(forKey: "LocalityData") as? [String:String] {
            locality = locale_data
        }
        
        if let rankings = defaults.dictionary(forKey: "Rankings") as? [String:Int] {
            self.rankings = rankings
        }
        
        rankingFetchInProgress = false
        
        prepElectric()
        prepWater()
        prepDriving()
        prepGas()
    }
    
    func logEnergyPoints() {
        if UserDefaults.standard.bool(forKey: "UpdateEP") {
            //Update the server because you've already uploaded once
            let parameters:[String: Any] = ["id":profId, "points":totalEnergyPoints]
            APIInterface.connectToServer(atEndpoint: "/updateEnergyPoints", withParameters: parameters, completion: {
                data in
                
                if data["status"] as! String == "Success" {
                    print("Sucessfully updated Energy Points")
                    if !self.rankingFetchInProgress {
                        self.fetchRankings()
                    }
                } else {
                    print(data["message"] as! String)
                }
            })
        } else {
            //Insert into the server because this is the first upload
            guard let locale = locality else {
                return
            }
            
            var parameters:[String: Any] = ["id":profId, "points":totalEnergyPoints]
            parameters["state"] = locale["State"]
            parameters["country"] = locale["Country"]
            parameters["city"] = locale["City"]
            APIInterface.connectToServer(atEndpoint: "/logEnergyPoints", withParameters: parameters, completion: {
                data in
                
                if data["status"] as! String == "Success" {
                    UserDefaults.standard.set(true, forKey: "UpdateEP")
                    
                    if !self.rankingFetchInProgress {
                        self.fetchRankings()
                    }
                } else {
                    print(data["message"] as! String)
                }
            })
        }
    }
    
    func fetchRankings() {
        guard let locale = locality else {
            return
        }
        
        rankingFetchInProgress = true
        
        var parameters:[String:Any] = ["id":profId]
        parameters["state"] = locale["State"]
        parameters["country"] = locale["Country"]
        
        APIInterface.connectToServer(atEndpoint: "/getStateRank", withParameters: parameters, completion: {
            data in
            
            if data["status"] as! String == "Success" {
                self.rankings["StateRank"] = data["Rank"] as? Int
                self.rankings["StateCount"] = data["Count"] as? Int
                
                if self.rankings.keys.count == 4 {
                    self.rankingFetchInProgress = false
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue:APINotifications.stateRank.rawValue), object: nil)
                }
            } else {
                print(data["message"] as! String)
            }
        })
        
        parameters["city"] = locale["City"]
        
        APIInterface.connectToServer(atEndpoint: "/getCityRank", withParameters: parameters, completion: {
            data in
            
            if data["status"] as! String == "Success" {
                self.rankings["CityRank"] = data["Rank"] as? Int
                self.rankings["CityCount"] = data["Count"] as? Int
                
                if self.rankings.keys.count == 4 {
                    self.rankingFetchInProgress = false
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue:APINotifications.cityRank.rawValue), object: nil)
                }
            } else {
                print(data["message"] as! String)
            }
        })
    }
    
    private func prepElectric() {
        //https://www.eia.gov/tools/faqs/faq.cfm?id=97&t=3
        let  electricData = GreenData(name: "Electric", xLabel:"Month", yLabel: "kWh", base: 901, averageLabel:"kWh per Day", icon:Icon.electric_white)
        
        //http://solarexpert.com/2013/11/07/how-many-solar-panels-are-needed-for-a-2000-square-foot-home/
        electricData.baselines["Solar Panels"] = 12
        
        
        let defaults = UserDefaults.standard
        if let bonusDict = defaults.dictionary(forKey: "Electric:bonus") {
            electricData.bonusDict = bonusDict as! [String:Int]
        } else {
            electricData.bonusDict["Solar Panels"] = 0;
        }
        
        if let data = defaults.dictionary(forKey: "Electric:data") {
            electricData.data = data as! [String:Int]
        }
        
        //If you were to try and load the e_factor from the web here, under the current code, an endless loop would be created
        if defaults.object(forKey: "e_factor") != nil {
            let conversionFactor = defaults.double(forKey: "e_factor")
            electricData.calculateCO2 = {
                point in
                
                return point * conversionFactor/1000
            }
        } else {
            electricData.calculateCO2 = {
                point in
                //1232.8 is the average conversion factor in lbs/MWh, so at least you can present some data with no internet
                return point * 1232.8/1000
            }
        }
        
        CoreDataHelper.fetch(data: electricData)
        electricData.recalculateEP()
        
        electricData.attributes.append("General")
        electricData.descriptions.append("Electric consumption is one of the largest contributers to an individuals carbon footprint. The average American consums 901 Kilowatt-Hours of Energy per month. You can find the Kilowatt-Hour consumption at the bottom of your electricity bill.")
        
        electricData.attributes.append("Solar Panels")
        electricData.descriptions.append("One way to make your electric consumption greener is to install solar panels. Just 12 solar panels can power a 2000 square foot home!")
        
        
        
        data["Electric"] = electricData
    }
    
    private func prepWater() {
        //https://www.epa.gov/watersense/how-we-use-water
        let waterData = GreenData(name: "Water", xLabel:"Month", yLabel:"Gallons", base:9000, averageLabel:"Gallons Per Day", icon: Icon.water_white)
        waterData.calculateEP = {
            base, point in
            let diff = base - point
            if diff < 0 {
                return Int(-1*pow(-1 * diff, 1.0/3.0))
            } else {
                return Int(pow(diff, 1.0/3.0))
            }
        }
        
        waterData.calculateCO2 = {
            _ in
            //Since water doesn't count towards CO2
            return 0
        }
        
        //http://www.home-water-works.org/indoor-use/showers
        waterData.baselines["Shower length"] = 8
        
        waterData.baselines["Laundry Frequency"] = 3
        //https://www.reference.com/health/many-times-day-should-toilet-ae709668021a63cb
        waterData.baselines["Bathroom Frequency"] = 10
        
        let defaults = UserDefaults.standard
        if let bonusDict = defaults.dictionary(forKey: "Water:bonus") {
            waterData.bonusDict = bonusDict as! [String:Int]
        } else {
            waterData.bonusDict["Shower length"] = 0
            waterData.bonusDict["Laundry Frequency"] = 0
            waterData.bonusDict["Bathroom Frequency"] = 0
        }
        
        if let data = defaults.dictionary(forKey: "Water:data") {
            waterData.data = data as! [String:Int]
        }
        
        CoreDataHelper.fetch(data: waterData)
        
        waterData.attributes.append("General")
        waterData.descriptions.append("An easy resource to waste is water because we use it so much in our daily lives. The average amount of water the average American uses in a month is 12,000 gallons. Reducing water consumption is another step you can take towards being green.")
        
        waterData.attributes.append("Shower Length")
        waterData.descriptions.append("The quickest way to cut down your water consumption is to cut down the length of your showers. The average American takens an 8 minute shower, but bringing this down to even just 5 minutes can have a dramatic effect over time.")
        
        waterData.attributes.append("Laundry Frequency")
        waterData.descriptions.append("Another large use of water is in doing the laundry. The number of times an average American does laundry in a week is 3 times.")
        
        waterData.attributes.append("Bathroom Frequency")
        waterData.descriptions.append("Although it may not seem like it, each time you flush the toilet, a substantial amount of water is used. The average American flushes the toilet 10 times a day.")
        
        waterData.recalculateEP()
        
        data["Water"] = waterData
    }
    
    private func prepDriving() {
        let drivingData = DrivingData()
        
        //https://www.reference.com/world-view/many-cars-average-american-family-own-f0e6dffd882f2857
        
        //Miles per gallon for the car and number of cars
        drivingData.baselines["Number of Cars"] = 2
        drivingData.baselines["Average MPG"] = 22
        //http://www.businessinsider.com/heres-how-much-the-average-american-walks-every-day-2015-7 (5900 steps - 3 miles, so at 5 mph, about 30 minutes)
        drivingData.baselines["Walking/Biking"] = 30
        
        drivingData.bonus = {
            base, attr in
            
            if drivingData.data["Average MPG"] == 0 || attr == 0 {
                return 0
            }
            
            let additiveMiles = 5.0 * Double(attr)*30/60.0
            print("Eco-Miles: \(additiveMiles)")
            let additive = drivingData.co2Emissions(additiveMiles, drivingData.data["Average MPG"]!)
            print("Eco-Emission: \(additive)")
            
            return Int(additive)
        }
        
        let defaults = UserDefaults.standard
        if let bonusDict = defaults.dictionary(forKey: "Driving:bonus") {
            drivingData.bonusDict = bonusDict as! [String:Int]
        } else {
            drivingData.bonusDict["Walking/Biking"] = 0
        }
        
        if let data = defaults.dictionary(forKey: "Driving:data") {
            drivingData.data = data as! [String:Int]
        } else {
            drivingData.data["Number of Cars"] = 0
            //If they have two cars, its the sum of their mpgs/number of cars
            drivingData.data["Average MPG"] = 0
        }
        
        CoreDataHelper.fetch(data: drivingData)
        
        drivingData.attributes.append("General")
        drivingData.descriptions.append("We directly contribute to the carbon dioxide in our atmosphere when we drive our cars. On average, each American emits 390 kilograms of Carbon Dioxide into the air each month. This number is calculated by the following equation: 8.887 * miles/mpg")
        
        drivingData.attributes.append("Average MPG")
        drivingData.descriptions.append("The average number of miles per gallon of a car is 22 mpg. Cars with higher mileage ratings emit less carbon dioxide over the same amount of distance. Your average MPG is calculated by adding up the mpg of each vehicle you own and dividing by the numer of vehicles you own.")
        
        drivingData.attributes.append("Number of Cars")
        drivingData.descriptions.append("The average American owns two cars. Recording data for each car you own (excluding electric vehicles) will lead to a more accurate picture of your carbon footprint")
        
        drivingData.attributes.append("Walking/Biking")
        drivingData.descriptions.append("The more you can walk or bike to places, the less your carbon footprint will be. The average American should be walking 30 minutes each day.")
        
        drivingData.recalculateEP()
        
        data["Driving"] = drivingData
    }
    
    private func prepGas() {
        //https://www.eia.gov/pub/oil_gas/natural_gas/feature_articles/2010/ngtrendsresidcon/ngtrendsresidcon.pdf
        //http://www.nationmaster.com/country-info/stats/Energy/Natural-gas/Consumption-per-capita
        let gasData = GreenData(name: "Gas", xLabel: "Month", yLabel: "Therms", base: 61, averageLabel: "Therms per Day", icon: Icon.fire_white)
        
        gasData.calculateCO2 = {
            point in
            //See spreadsheet for this conversion factor
            return point*11.7
        }
        
        CoreDataHelper.fetch(data: gasData)
        
        gasData.attributes.append("General")
        gasData.descriptions.append("Although it is cleaner burning than gasoline and other fossil fuels, natural gas, or methane, is a strong greenhouse gas. Leakage while mining it, as well as carbon dioxide released while burning it, contribute to the changing climate. The average American uses 0.7 Mcf of natural gas per month, which is the same as 700 Ccf or 700 Therms")
        
        gasData.recalculateEP()
        
        data["Gas"] = gasData
    }
}

struct Colors {
    static let green = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
    static let darkGreen = UIColor(red: 45/255, green: 191/255, blue: 122/255, alpha: 1.0)
    static let red = UIColor(red:231/255, green: 76/255, blue:60/255, alpha:1.0)
    static let blue = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
    static let purple = UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1.0)
    static let grey = UIColor(red: 127/255, green: 140/255, blue: 141/255, alpha: 1.0)
    
    static let options = [green, red, blue, purple, darkGreen]
}

extension Icon {
    static let logo_white = UIImage(named: "plant")!
    static let electric_white = UIImage(named: "Lightning_Bolt_White")!
    static let water_white = UIImage(named: "Water-Drop")!
    static let smoke_white = UIImage(named: "Smoke")!
    static let info_white = UIImage(named: "Information-256")
    static let fire_white = UIImage(named: "Fire")!
    static let road_white = UIImage(named: "Road")!
    
    static let chart_green = UIImage(named: "Chart_Green")!
}

extension Date {
    static func monthFormat(string:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.date(from: string)!
    }
    
    static func monthFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.string(from: date)
    }
    
    //Returns the number of months from one date to another
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    
    func nextMonth() -> Date {
        return Calendar.current.date(byAdding: .month, value: 1, to: self, wrappingComponents: false) ?? self
    }
}
