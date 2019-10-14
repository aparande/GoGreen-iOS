//
//  GreenfootModal.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/29/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import Foundation
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
    
    var locality:Location?
    
    var rankings:[String:Int]
    
    private var rankingFetchInProgress: Bool
    
    init() {
        data = [:]
        rankings = [:]
        
        let defaults = UserDefaults.standard
        
        if let locale_data = Location.fromDefaults(withKey: "LocalityData") {
            locality = locale_data
            //SettingsManager.sharedInstance.shouldUseLocation = true
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
        
        var parameters:[String: Any] = ["id":SettingsManager.sharedInstance.profile.id!, "points":totalEnergyPoints]
        parameters["state"] = locale.administrativeArea
        parameters["country"] = locale.country
        parameters["city"] = locale.locality
        
        let id = [APIRequestType.log.rawValue, "EP"].joined(separator: ":")
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
        
        var parameters:[String:Any] = ["id":SettingsManager.sharedInstance.profile.id!]
        parameters["state"] = locale.administrativeArea
        parameters["country"] = locale.country
        
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
        
        parameters["city"] = locale.locality
        
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
            
            guard let setting = reminderSettings[dataType] else {
                print("Could not queue reminder because reminder settings for \(dataType.rawValue) is null")
                return
            }
            
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
            let identifier = "REM:\(dataType.rawValue):\(Date.monthFormat(date: nextDate))"
            print("Scheduling Reminder for \(identifier)")
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request, withCompletionHandler: {
                _ in
                
                SettingsManager.sharedInstance.scheduledReminders[dataType] = identifier
            })
        }
    }
    
    private func loadAttributes(forDataType dataType: GreenDataType, ofCategory category: String) -> [String: GreenAttribute]? {
        let defaults = UserDefaults.standard
        
        if let json = defaults.data(forKey: dataType.rawValue+":\(category)") {
            var resultDict: [String: GreenAttribute] = [:]
            do {
                resultDict = try JSONDecoder().decode([String:GreenAttribute].self, from: json)
            } catch {
                do {
                    let jsonObj = try JSONSerialization.jsonObject(with: json, options: .mutableContainers) as? [String:Any]
                    for (key, value) in jsonObj! {
                        let attributeObj = value as! NSDictionary
                        let attribute = GreenAttribute(value: attributeObj["value"]! as! Int, lastUpdated: Date(timeIntervalSince1970: attributeObj["lastUpdated"] as! Double))
                        resultDict[key] = attribute
                    }
                } catch {
                    return nil
                }
            }
            
            return resultDict
        } else {
            if let storedDict = defaults.dictionary(forKey: dataType.rawValue+":\(category)") as? [String:Int] {
                var resultDict:[String: GreenAttribute] = [:]
                for (key, value) in storedDict {
                    resultDict[key] = GreenAttribute(value: value, lastUpdated:Date())
                }
                return resultDict
            } else {
                return nil
            }
        }
    }
    
    private func prepElectric() {
        //https://www.eia.gov/tools/faqs/faq.cfm?id=97&t=3
        let  electricData = GreenData(name: GreenDataType.electric.rawValue, xLabel:"Month", yLabel: "kWh", base: 901, averageLabel:"kWh per Day", icon:Icon.electric_emblem)
        
        //http://solarexpert.com/2013/11/07/how-many-solar-panels-are-needed-for-a-2000-square-foot-home/
        electricData.baselines["Solar Panels"] = 12
        
        
        let defaults = UserDefaults.standard
        
        if let bonusDict = loadAttributes(forDataType: GreenDataType.electric, ofCategory: "bonus") {
            electricData.bonusDict = bonusDict
        } else {
            electricData.bonusDict["Solar Panels"] = GreenAttribute(value: 0, lastUpdated: Date());
        }
        
        if let dataDict = loadAttributes(forDataType: GreenDataType.electric, ofCategory: "data") {
            electricData.data = dataDict
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
        
        if let bonusDict = loadAttributes(forDataType: GreenDataType.water, ofCategory: "bonus") {
            waterData.bonusDict = bonusDict
        } else {
            waterData.bonusDict["Shower Length"] = GreenAttribute(value: 0, lastUpdated: Date())
            waterData.bonusDict["Laundry Frequency"] = GreenAttribute(value: 0, lastUpdated: Date())
            waterData.bonusDict["Bathroom Frequency"] = GreenAttribute(value: 0, lastUpdated: Date())
        }
        
        if let dataDict = loadAttributes(forDataType: GreenDataType.water, ofCategory: "data") {
            waterData.data = dataDict
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
            
            if drivingData.data["Average MPG"]!.value == 0 || attr <= 30 {
                return 0
            }
            
            //Calculate how many more miles the person walks than average and multiply it by 10 to make it possile to get energy points
            let additiveMiles = 10 * (5 * (Double(attr) - 30)/60)
            //Convert that into CO2
            let additive = drivingData.calculateCO2(additiveMiles)
            
            print("Eco-Miles: \(additiveMiles)")
            print("Eco-Emission: \(additive)")
            
            return Int(additive)
        }
        
        if let bonusDict = loadAttributes(forDataType: GreenDataType.driving, ofCategory: "bonus") {
            drivingData.bonusDict = bonusDict
        } else {
            drivingData.bonusDict["Walking/Biking"] = GreenAttribute(value: 0, lastUpdated: Date())
        }
        
        if let dataDict = loadAttributes(forDataType: GreenDataType.driving, ofCategory: "data") {
            drivingData.data = dataDict
        } else {
            drivingData.data["Number of Cars"] = GreenAttribute(value: 0, lastUpdated: Date())
            //If they have two cars, its the sum of their mpgs/number of cars
            drivingData.data["Average MPG"] = GreenAttribute(value: 0, lastUpdated: Date())
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
