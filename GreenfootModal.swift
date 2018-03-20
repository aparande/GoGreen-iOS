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
import UserNotifications

class GreenfootModal {
    static let sharedInstance = GreenfootModal()
    
    var data:[GreenDataType:GreenData]
    
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
    
    var rankings:[String:Int]
    
    private var rankingFetchInProgress: Bool
    
    init() {
        data = [:]
        rankings = [:]
        
        let defaults = UserDefaults.standard
        
        if let locale_data = defaults.dictionary(forKey: "LocalityData") as? [String:String] {
            locality = locale_data
            SettingsManager.sharedInstance.shouldUseLocation = true
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
        //Insert into the server because this is the first upload
        guard let locale = locality else {
            return
        }
        
        var parameters:[String: Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!, "points":totalEnergyPoints]
        parameters["state"] = locale["State"]
        parameters["country"] = locale["Country"]
        parameters["city"] = locale["City"]
        
        let id = [APIRequestType.add.rawValue, "EP"].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: id, atEndpoint: "logEnergyPoints", withParameters: parameters, andSuccessFunction: {
            data in
            
            UserDefaults.standard.set(true, forKey: "UpdateEP")
            
            if !self.rankingFetchInProgress {
                self.fetchRankings()
            }
        }, andFailureFunction: nil)
    }
    
    func fetchRankings() {
        guard let locale = locality else {
            return
        }
        
        rankingFetchInProgress = true
        
        var parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile["profId"]!]
        parameters["state"] = locale["State"]
        parameters["country"] = locale["Country"]
        
        let stateId = [APIRequestType.get.rawValue, "STATE_RANK"].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: stateId, atEndpoint: "getStateRank", withParameters: parameters, andSuccessFunction: {
            data in
            
            self.rankings["StateRank"] = data["Rank"] as? Int
            self.rankings["StateCount"] = data["Count"] as? Int
            
            if self.rankings.keys.count == 4 {
                self.rankingFetchInProgress = false
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:APINotifications.stateRank.rawValue), object: nil)
            }
        }, andFailureFunction: nil)
        
        parameters["city"] = locale["City"]
        
        let cityId = [APIRequestType.get.rawValue, "CITY_RANK"].joined(separator: ":")
        APIRequestManager.sharedInstance.queueAPICall(identifiedBy: cityId, atEndpoint: "getCityRank", withParameters: parameters, andSuccessFunction: {
            data in
            
            self.rankings["CityRank"] = data["Rank"] as? Int
            self.rankings["CityCount"] = data["Count"] as? Int
            
            if self.rankings.keys.count == 4 {
                self.rankingFetchInProgress = false
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:APINotifications.cityRank.rawValue), object: nil)
            }
        }, andFailureFunction: nil)
    }
    
    func queueReminder(dataType: GreenDataType) {
        if SettingsManager.sharedInstance.canNotify {
            print("App Can Notify")
            guard let reminderSettings = SettingsManager.sharedInstance.reminderTimings else {
                print("Could not queue reminder because reminder settings is null")
                return
            }
            
            let setting = reminderSettings[dataType]!
            if setting == .None {
                return
            }
            
            if let notification = SettingsManager.sharedInstance.scheduledReminders[dataType] {
                print("Not scheduling reminder because one is already queued: \(notification)")
                return
            }
            
            print("Queuing Notification")
            
            let calendar = NSCalendar.current
            let today = Date()
            
            var nextDate:Date!
            switch setting {
            case .FirstOfMonth:
                var components = DateComponents()
                components.day = 1
                nextDate = calendar.nextDate(after: today, matching: components, matchingPolicy: .nextTime)
            case .OneMonth:
                nextDate = calendar.date(byAdding: .month, value: 1, to: today)
            case .None:
                return
            }
            
            let timeInterval = nextDate.timeIntervalSince(today)
            let content = UNMutableNotificationContent()
            content.title = NSString.localizedUserNotificationString(forKey:
                "Reminder: Add to your \(dataType.rawValue) data", arguments: nil)
            content.body = NSString.localizedUserNotificationString(forKey:
                "It's that time of month again! Don't forget to add data to \(dataType.rawValue) in GoGreen", arguments: nil)
            
            // Deliver the notification in five seconds.
            content.sound = UNNotificationSound.default()
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval,
                                                            repeats: false)
            
            // Schedule the notification.
            let identifier = "REM:\(dataType.rawValue):\(nextDate)"
            print("Scheduling Reminder for \(identifier)")
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: {
                _ in
                
                SettingsManager.sharedInstance.scheduledReminders[dataType] = identifier
            })
        }
    }
    
    private func prepElectric() {
        //https://www.eia.gov/tools/faqs/faq.cfm?id=97&t=3
        let  electricData = GreenData(name: GreenDataType.electric.rawValue, xLabel:"Month", yLabel: "kWh", base: 901, averageLabel:"kWh per Day", icon:Icon.electric_emblem)
        
        //http://solarexpert.com/2013/11/07/how-many-solar-panels-are-needed-for-a-2000-square-foot-home/
        electricData.baselines["Solar Panels"] = 12
        
        
        let defaults = UserDefaults.standard
        
        if let json = defaults.string(forKey: GreenDataType.electric.rawValue+":bonus") {
            let bonusDict = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            electricData.bonusDict = bonusDict!
        } else {
            if let bonusDict = defaults.dictionary(forKey: GreenDataType.electric.rawValue+":bonus") as? [String:Int] {
                for (key, value) in bonusDict {
                    electricData.bonusDict[key] = GreenAttribute(value: value, lastUpdated:Date())
                }
            } else {
                electricData.bonusDict["Solar Panels"] = GreenAttribute(value: 0, lastUpdated: Date());
            }
        }
        
        if let json = defaults.string(forKey: GreenDataType.electric.rawValue+":data") {
            let data = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            electricData.data = data!
        } else {
            if let data = defaults.dictionary(forKey: GreenDataType.electric.rawValue+":data") as? [String:Int] {
                for (key, value) in data {
                    electricData.data[key] = GreenAttribute(value: value, lastUpdated:Date())
                }
            }
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
        
        electricData.calculateEP = {
            base, point in
            
            let diff = (electricData.calculateCO2(base)-electricData.calculateCO2(point))/100
            return Int(floor(diff))
        }
        
        CoreDataHelper.fetch(data: electricData)
        electricData.recalculateEP()
        
        electricData.descriptions["General"] = "Electric consumption is one of the largest contributers to an individuals carbon footprint. The average American consums 901 Kilowatt-Hours of Energy per month. You can find the Kilowatt-Hour consumption at the bottom of your electricity bill."
        
        electricData.descriptions["Solar Panels"] = "One way to make your electric consumption greener is to install solar panels. Just 12 solar panels can power a 2000 square foot home!"
        
        
        
        data[GreenDataType.electric] = electricData
    }
    
    private func prepWater() {
        //https://www.epa.gov/watersense/how-we-use-water
        let waterData = GreenData(name: GreenDataType.water.rawValue, xLabel:"Month", yLabel:"Gallons", base:9000, averageLabel:"Gallons Per Day", icon: Icon.water_emblem)
        
        waterData.calculateEP = {
            base, point in
            let diff = (base - point)/500
            return Int(floor(diff))
        }
        
        waterData.calculateCO2 = {
            _ in
            //Since water doesn't count towards CO2
            return 0
        }
        
        //http://www.home-water-works.org/indoor-use/showers
        waterData.baselines["Shower Length"] = 8
        
        waterData.baselines["Laundry Frequency"] = 3
        //https://www.reference.com/health/many-times-day-should-toilet-ae709668021a63cb
        waterData.baselines["Bathroom Frequency"] = 10
        
        waterData.bonus = {
            base, attr in
            return (attr != 0 && attr < base) ? 5*(base-attr) : 0
        }
        
        let defaults = UserDefaults.standard
        if let json = defaults.string(forKey: GreenDataType.water.rawValue+"bonus") {
            let bonusDict = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            waterData.bonusDict = bonusDict!
        } else {
            if let bonusDict = defaults.dictionary(forKey: GreenDataType.water.rawValue+"bonus") as? [String:Int] {
                for (key, value) in bonusDict {
                    waterData.bonusDict[key] = GreenAttribute(value: value, lastUpdated: Date())
                }
            } else {
                waterData.bonusDict["Shower Length"] = GreenAttribute(value: 0, lastUpdated: Date())
                waterData.bonusDict["Laundry Frequency"] = GreenAttribute(value: 0, lastUpdated: Date())
                waterData.bonusDict["Bathroom Frequency"] = GreenAttribute(value: 0, lastUpdated: Date())
            }
        }
        
        if let json = defaults.string(forKey: GreenDataType.water.rawValue+":data") {
            let data = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            waterData.data = data!
        } else {
            if let data = defaults.dictionary(forKey: GreenDataType.water.rawValue+":data") as? [String:Int] {
                for (key, value) in data {
                    waterData.data[key] = GreenAttribute(value: value, lastUpdated:Date())
                }
            }
        }
        
        CoreDataHelper.fetch(data: waterData)
        
        waterData.descriptions["General"] = "An easy resource to waste is water because we use it so much in our daily lives. The average amount of water the average American uses in a month is 9,000 gallons. Reducing water consumption is another step you can take towards being green."
        
        waterData.descriptions["Shower Length"] = "The quickest way to cut down your water consumption is to cut down the length of your showers. The average American takes an 8 minute shower, but bringing this down to just 5 minutes can have a dramatic effect over time."
        
        waterData.descriptions["Laundry Frequency"] = "Another large use of water is in doing the laundry. The number of times an average American does laundry in a week is 3 times."
        
        waterData.descriptions["Bathroom Frequency"] = "Although it may not seem like it, each time you flush the toilet, a substantial amount of water is used. The average American flushes the toilet 10 times a day."
        
        waterData.recalculateEP()
        
        data[GreenDataType.water] = waterData
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
            
            if drivingData.data["Average MPG"]!.value == 0 || attr == 0 {
                return 0
            }
            
            let additiveMiles = 5.0 * Double(attr)*30/60.0
            print("Eco-Miles: \(additiveMiles)")
            let additive = drivingData.calculateCO2(additiveMiles)
            print("Eco-Emission: \(additive)")
            
            return Int(additive)
        }
        
        let defaults = UserDefaults.standard
        if let json = defaults.string(forKey: GreenDataType.driving.rawValue+":bonus") {
            let bonusDict = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            drivingData.bonusDict = bonusDict!
        } else {
            if let bonusDict = defaults.dictionary(forKey: GreenDataType.driving.rawValue+":bonus") as? [String:Int] {
                for (key, value) in bonusDict {
                    drivingData.bonusDict[key] = GreenAttribute(value: value, lastUpdated: Date())
                }
            } else {
                drivingData.bonusDict["Walking/Biking"] = GreenAttribute(value: 0, lastUpdated: Date())
            }
        }
        
        if let json = defaults.string(forKey: GreenDataType.driving.rawValue+":data") {
            let data = try? JSONDecoder().decode([String:GreenAttribute].self, from: json.data(using: .utf8)!)
            drivingData.data = data!
        } else {
            if let data = defaults.dictionary(forKey: GreenDataType.driving.rawValue+":data") as? [String:Int] {
                for (key, value) in data {
                    drivingData.data[key] = GreenAttribute(value: value, lastUpdated: Date())
                }
            } else {
                drivingData.data["Number of Cars"] = GreenAttribute(value: 0, lastUpdated: Date())
                //If they have two cars, its the sum of their mpgs/number of cars
                drivingData.data["Average MPG"] = GreenAttribute(value: 0, lastUpdated: Date())
            }
        }
        
        CoreDataHelper.fetch(data: drivingData)
        
        drivingData.descriptions["General"] = "We directly contribute to the carbon dioxide in our atmosphere when we drive our cars. On average, each American emits 390 kilograms of Carbon Dioxide into the air each month. This number is calculated by the following equation: 8.887 * miles/mpg"
        
        drivingData.descriptions["Average MPG"] = "The average number of miles per gallon of a car is 22 mpg. Cars with higher mileage ratings emit less carbon dioxide over the same amount of distance. Your average MPG is calculated by adding up the mpg of each vehicle you own and dividing by the numer of vehicles you own."
        
        drivingData.descriptions["Number of Cars"] = "The average American owns two cars. Recording data for each car you own (excluding electric vehicles) will lead to a more accurate picture of your carbon footprint"
        
        drivingData.descriptions["Walking/Biking"] = "The more you can walk or bike to places, the less your carbon footprint will be. The average American should be walking 30 minutes each day."
        
        drivingData.recalculateEP()
        
        data[GreenDataType.driving] = drivingData
    }
    
    private func prepGas() {
        //https://www.eia.gov/pub/oil_gas/natural_gas/feature_articles/2010/ngtrendsresidcon/ngtrendsresidcon.pdf
        //http://www.nationmaster.com/country-info/stats/Energy/Natural-gas/Consumption-per-capita
        let gasData = GreenData(name: GreenDataType.gas.rawValue, xLabel: "Month", yLabel: "Therms", base: 61, averageLabel: "Therms per Day", icon: Icon.fire_emblem)
        
        gasData.calculateCO2 = {
            point in
            //See spreadsheet for this conversion factor
            return point*11.7
        }
        
        gasData.calculateEP = {
            base, point in
            
            let diff = (gasData.calculateCO2(base) - gasData.calculateCO2(point))/100
            return Int(floor(diff))
        }
        
        CoreDataHelper.fetch(data: gasData)
        
        gasData.descriptions["General"] = "Although it is cleaner burning than gasoline and other fossil fuels, natural gas, or methane, is a strong greenhouse gas. Leakage while mining it, as well as carbon dioxide released while burning it, contribute to the changing climate. The average American uses 0.7 Mcf of natural gas per month, which is the same as 700 Ccf or 700 Therms"
        
        gasData.recalculateEP()
        
        data[GreenDataType.gas] = gasData
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
    static let info_white = UIImage(named: "Information-256")!
    static let fire_white = UIImage(named: "Fire")!
    static let road_white = UIImage(named: "Road")!
    
    static let chart_green = UIImage(named: "Chart_Green")!
    static let lock = UIImage(named: "Lock")!
    static let person = UIImage(named: "Person")!
    
    static let electric_emblem = UIImage(named:"electric_emblem")!
    static let water_emblem = UIImage(named:"water_emblem")!
    static let leaf_emblem = UIImage(named:"Leaf_Emblem")!
    static let fire_emblem = UIImage(named:"fire_emblem")!
    static let road_emblem = UIImage(named:"road_emblem")!
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

extension String {
    func removeSpecialChars() -> String {
        let okayChars : Set<Character> =
            Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890")
        return String(self.filter {okayChars.contains($0) })
    }
}

enum GreenDataType:String {
    case electric = "Electricity"
    case water = "Water"
    case driving = "Driving"
    case gas = "Gas"
    
    static let allValues = [electric, water, driving, gas]
}
