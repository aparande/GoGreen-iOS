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

class GreenfootModal: NewsParserDelegate {
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
    
    var nyTimesXmlParser: NewsXMLParser
    var guardianXmlParser: NewsXMLParser
    var nasaXmlParser: NewsXMLParser
    var newsFeed = [Dictionary<String, String>]()
    
    init() {
        data = [:]
        
        nyTimesXmlParser = NewsXMLParser()
        guardianXmlParser = NewsXMLParser()
        nasaXmlParser = NewsXMLParser()

        
        nyTimesXmlParser.delegate = self
        guardianXmlParser.delegate = self
        nasaXmlParser.delegate = self
        
        nyTimesXmlParser.startParsingWithContentsOfUrl(feed: "New York Times", rssUrl: URL(string: "http://rss.nytimes.com/services/xml/rss/nyt/Environment.xml")!)
        guardianXmlParser.startParsingWithContentsOfUrl(feed: "The Guardian", rssUrl: URL(string: "https://www.theguardian.com/environment/climate-change/rss")!)
        nasaXmlParser.startParsingWithContentsOfUrl(feed: "NASA", rssUrl: URL(string: "https://climate.nasa.gov/news/rss.xml")!)
        
        prepElectric()
        prepWater()
        prepCO2()
        prepGas()
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

        if let serializableGraphData = defaults.object(forKey: "Electric:graph") as? [String:Double] {
            for (key, value) in serializableGraphData {
                electricData.addDataPoint(month: Date.stringToLongDate(date: key), y: value)
            }
        }
        
        electricData.attributes.append("General")
        electricData.descriptions.append("Electric consumption is one of the largest contributers to an individuals carbon footprint. The average American consums 901 Kilowatt-Hours of Energy per month. You can find the Kilowatt-Hour consumption at the bottom of your electricity bill.")
        
        electricData.attributes.append("Solar Panels")
        electricData.descriptions.append("One way to make your electric consumption greener is to install solar panels. Just 12 solar panels can power a 2000 square foot home!")
        
        data["Electric"] = electricData
    }
    
    private func prepWater() {
        //https://www3.epa.gov/watersense/pubs/indoor.html
        let waterData = GreenData(name: "Water", xLabel:"Month", yLabel:"Gallons", base:12000, averageLabel:"Gallons Per Day", icon: Icon.water_white)
        waterData.calculateEP = {
            base, point in
            //return Int(base/1000 - point/1000)
            let difference = Double(base-point)
            if difference < 0 {
                return Int(-sqrt(difference/(-10)))
            } else {
                return Int(sqrt(difference/10))
            }
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
        
        if let serializableGraphData = defaults.object(forKey: "Water:graph") as? [String:Double] {
            for (key, value) in serializableGraphData {
                waterData.addDataPoint(month: Date.stringToLongDate(date: key), y: value)
            }
        }
        
        waterData.attributes.append("General")
        waterData.descriptions.append("An easy resource to waste is water because we use it so much in our daily lives. The average amount of water the average American uses in a month is 12,000 gallons. Reducing water consumption is another step you can take towards being green.")
        
        waterData.attributes.append("Shower Length")
        waterData.descriptions.append("The quickest way to cut down your water consumption is to cut down the length of your showers. The average American takens an 8 minute shower, but bringing this down to even just 5 minutes can have a dramatic effect over time.")
        
        waterData.attributes.append("Laundry Frequency")
        waterData.descriptions.append("Another large use of water is in doing the laundry. The number of times an average American does laundry in a week is 3 times.")
        
        waterData.attributes.append("Bathroom Frequency")
        waterData.descriptions.append("Although it may not seem like it, each time you flush the toilet, a substantial amount of water is used. The average American flushes the toilet 10 times a day.")
        
        data["Water"] = waterData
    }
    
    private func prepCO2() {
        let co2Data = EmissionsData()
        
        //https://www.reference.com/world-view/many-cars-average-american-family-own-f0e6dffd882f2857
        
        //Miles per gallon for the car and number of cars
        co2Data.baselines["Number of Cars"] = 2
        co2Data.baselines["Average MPG"] = 22
        //http://www.businessinsider.com/heres-how-much-the-average-american-walks-every-day-2015-7 (5900 steps - 3 miles, so at 5 mph, about 30 minutes)
        co2Data.baselines["Walking/Biking"] = 30
        
        co2Data.bonus = {
            base, attr in
            
            if co2Data.data["Average MPG"] == 0 || attr == 0 {
                return 0
            }
            
            let additiveMiles = 5.0 * Double(attr)*30/60.0
            print("Eco-Miles: \(additiveMiles)")
            let additive = co2Data.co2Emissions(additiveMiles, co2Data.data["Average MPG"]!)
            print("Eco-Emission: \(additive)")
            
            return Int(additive)
        }
        
        let defaults = UserDefaults.standard
        if let bonusDict = defaults.dictionary(forKey: "Emissions:bonus") {
            co2Data.bonusDict = bonusDict as! [String:Int]
        } else {
            co2Data.bonusDict["Walking/Biking"] = 0
        }
        
        if let data = defaults.dictionary(forKey: "Emissions:data") {
            co2Data.data = data as! [String:Int]
        } else {
            co2Data.data["Number of Cars"] = 0
            //If they have two cars, its the sum of their mpgs/number of cars
            co2Data.data["Average MPG"] = 0
        }
        
        if let serializableGraphData = defaults.object(forKey: "Emissions:graph") as? [String:Double] {
            for (key, value) in serializableGraphData {
                co2Data.addDataPoint(month: Date.stringToLongDate(date: key), y: value)
            }
        }
        
        co2Data.attributes.append("General")
        co2Data.descriptions.append("We directly contribute to the carbon dioxide in our atmosphere when we drive our cars. On average, each American emits 390 kilograms of Carbon Dioxide into the air each month. This number is calculated by the following equation: 8.887 * miles/mpg")
        
        co2Data.attributes.append("Average MPG")
        co2Data.descriptions.append("The average number of miles per gallon of a car is 22 mpg. Cars with higher mileage ratings emit less carbon dioxide over the same amount of distance. Your average MPG is calculated by adding up the mpg of each vehicle you own and dividing by the numer of vehicles you own.")
        
        co2Data.attributes.append("Number of Cars")
        co2Data.descriptions.append("The average American owns two cars. When you record this number, do not record electric vehicles.")
        
        co2Data.attributes.append("Walking/Biking")
        co2Data.descriptions.append("The more you can walk or bike to places, the less your carbon footprint will be. The average American should be walking 30 minutes each day.")
        
        data["Emissions"] = co2Data
    }
    
    private func prepGas() {
        //https://www.eia.gov/pub/oil_gas/natural_gas/feature_articles/2010/ngtrendsresidcon/ngtrendsresidcon.pdf
        
        let gasData = GreenData(name: "Gas", xLabel: "Month", yLabel: "Therms", base: 700, averageLabel: "Therms per Day", icon: Icon.fire_white)
        gasData.calculateEP = {
            base, point in
            return Int((1 - point/base)*100)
        }
        
        let defaults = UserDefaults.standard
        
        if let serializableGraphData = defaults.object(forKey: "Gas:graph") as? [String:Double] {
            for (key, value) in serializableGraphData {
                gasData.addDataPoint(month: Date.stringToLongDate(date: key), y: value)
            }
        }
        
        gasData.attributes.append("General")
        gasData.descriptions.append("Although it is cleaner burning than gasoline and other fossil fuels, natural gas, or methane, is a strong greenhouse gas. Leakage while mining it, as well as carbon dioxide released while burning it, contribute to the changing climate. The average American uses 0.7 Mcf of natural gas per month, which is the same as 700 Ccf or 700 Therms")
        
        data["Gas"] = gasData
    }
    
    func parsingWasFinished(feed:String, parser:NewsXMLParser) {
        newsFeed.append(contentsOf: parser.arrParsedData)

        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        newsFeed.sort(by: {
            let dateOne = formatter.date(from: $0["pubDate"]!)!
            let dateTwo = formatter.date(from: $1["pubDate"]!)!
                
            return dateOne > dateTwo
        })
    }
}

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
        
        dataName = name
        graphData = [:]
        energyPoints = 0
        baseline = base
        self.averageLabel = averageLabel
        self.icon = icon
        
        self.calculateEP = {
            base, point in
            return Int(base - point)
        }
        
        bonus = {
            base, attr in
            return (attr > base) ? 5*(attr-base) : 0
        }
    }
    
    func addDataPoint(month:Date, y:Double) {
        graphData[month] = y
        energyPoints += calculateEP(baseline, y)
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
                addDataPoint(month: date, y: co2)
            }
        }
    }
}

struct Colors {
    static let green = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
}

extension Icon {
    static let logo_white = UIImage(named: "plant")!
    static let electric_white = UIImage(named: "Lightning_Bolt_White")!
    static let water_white = UIImage(named: "Water-Drop")!
    static let smoke_white = UIImage(named: "Smoke")!
    static let info_white = UIImage(named: "Information-256")
    static let fire_white = UIImage(named: "Fire")!
    
    static let chart_green = UIImage(named: "Chart_Green")!
    static let fire_green = UIImage(named: "Fire_Green")!
    static let home_green = UIImage(named: "Home_Green")!
    static let electric_green = UIImage(named: "Lighning_Bolt_Green")!
    static let water_green = UIImage(named: "Water-Drop_Green")!
}

extension Date {
    static func monthFormat(date:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        return formatter.date(from: date)!
    }
    
    static func longFormat(date:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        let theDate = formatter.date(from: date)!
        formatter.dateFormat = "E, MM/dd hh:mm a"
        return formatter.string(from: theDate)
    }
    
    static func longDateToString(date:Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        return formatter.string(from: date)
    }
    
    static func stringToLongDate(date:String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: date)!
    }
}
