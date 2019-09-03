//
//  SourceAggregator.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/4/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

class SourceAggregator {
    var sources: [CarbonSource] = []
    var points: [Measurement] = []
    
    var unit: CarbonUnit!
    
    init(fromSources sources: [CarbonSource]) {
        self.sources = sources
        commonInit()
    }
    
    init(fromCategories sourceCategories: [CarbonSource.SourceCategory]) throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext, fromCategories: sourceCategories)
        } catch {
            throw CoreDataError.fetchError
        }
        
        commonInit()
    }
    
    init(fromTypes sourceTypes: [CarbonSource.SourceType]) throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext, withTypes: sourceTypes)
        } catch {
            throw CoreDataError.fetchError
        }
        
        commonInit()
    }
    
    init() throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext)
        } catch {
            throw CoreDataError.fetchError
        }
        
        commonInit()
    }
    
    private func commonInit() {
        generatePoints()
    }
    
    private func generatePoints() {
        if sources.count == 1 {
            self.points = sources[0].points
        } else {
            createAggregates()
        }
    }
    
    func refresh() {
        createAggregates()
    }
    
    private func createAggregates() {
        self.points = []
        var dateGroups:[NSDate : Double] = [:]
        
        for source in sources {
            for point in source.points {
                dateGroups[point.month] = point.carbonValue + (dateGroups[point.month] ?? 0.0)
            }
        }
        
        for (date, value) in dateGroups {
            let measurement = CarbonValue(rawValue: value, month: date)
            self.points.append(measurement)
        }
        
        self.points.sort {$0.month.compare($1.month as Date) == .orderedAscending}
        self.unit = self.points.first?.unit
    }
}

//MARK: Source Aggregator Math
extension SourceAggregator {
    func sumCarbon() -> Double {
        var sum = 0.0
        
        for source in sources {
            for data in source.points {
                #warning("This neglects units (i.e tons vs lbs)")
                sum += data.carbonValue
            }
        }
        
        return sum
    }
    
    func carbonEmitted(on date: Date) -> Double {
        var sum = 0.0
        
        for source in sources {
            let data = source.points.filter({$0.month.compare(date) == .orderedSame})
            if data.count == 1 {
                sum += data[0].carbonValue
            }
        }
        
        return sum
    }
}
