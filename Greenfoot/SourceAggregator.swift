//
//  SourceAggregator.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/4/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

class SourceAggregator {
    typealias SourceType = CarbonSource.SourceType
    typealias SourceCategory = CarbonSource.SourceCategory
    
    private var boundSourceTypes:Set<SourceType>
    
    var sources: [CarbonSource] = []
    var points: [Measurement] = []
    
    var unit: CarbonUnit!
    
    init(fromSources sources: [CarbonSource]) {
        self.sources = sources
        self.boundSourceTypes = []
        
        commonInit()
    }
    
    init(fromCategories sourceCategories: [CarbonSource.SourceCategory]) throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext, fromCategories: sourceCategories)
        } catch {
            throw CoreDataError.fetchError
        }
        
        self.boundSourceTypes = []
        for category in sourceCategories {
            for type in category.types {
                if !self.boundSourceTypes.contains(type) {
                    self.boundSourceTypes.insert(type)
                }
            }
        }
        
        commonInit()
    }
    
    init(fromTypes sourceTypes: [CarbonSource.SourceType]) throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext, withTypes: sourceTypes)
        } catch {
            throw CoreDataError.fetchError
        }
        
        self.boundSourceTypes = []
        for type in sourceTypes {
            if !self.boundSourceTypes.contains(type) {
                self.boundSourceTypes.insert(type)
            }
        }
        
        commonInit()
    }
    
    init() throws {
        do {
            sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext)
        } catch {
            throw CoreDataError.fetchError
        }
        
        self.boundSourceTypes = []
        for type in SourceType.all {
            if !self.boundSourceTypes.contains(type) {
                self.boundSourceTypes.insert(type)
            }
        }
        
        commonInit()
    }
    
    private func commonInit() {
        generatePoints()
    }
    
    private func generatePoints() {
        if sources.count == 1 {
            self.points = computeDerivatives(for: sources[0])
            self.unit = sources[0].defaultUnit
        } else {
            self.createAggregates()
        }
    }
    
    func refresh() {
        do {
            if self.boundSourceTypes.count != 0 {
                self.sources = try CarbonSource.all(inContext: DBManager.shared.backgroundContext, withTypes: self.boundSourceTypes.compactMap({$0}))
            }
        } catch {
            print("Couldn't refresh source aggregator")
        }
        
        generatePoints()
    }
    
    func addSource(_ source: CarbonSource) {
        if !sources.contains(source) {
            sources.append(source)
        }
    }
    
    private func createAggregates() {
        self.points = []
        var dateGroups:[NSDate : Double] = [:]
        
        for source in sources {
            for point in computeDerivatives(for: source) {
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
    
    private func computeDerivatives(for source: CarbonSource) -> [Measurement] {
        if source.conversionType == .direct {
            return source.points
        }
        
        if source.sourceType == .odometer {
            return DifferenceFilter().apply(to: source)
        }
        return source.points
    }
}

//MARK: Source Aggregator Math
extension SourceAggregator {
    func sumCarbon() -> CarbonValue {
        var sum = 0.0
        
        for point in points {
            sum += point.carbonValue
        }
        
        print("The sum is \(sum)")
        
        return CarbonValue(rawValue: sum)
    }
    
    func carbonEmitted(on date: Date) -> CarbonValue {
        var sum = 0.0
        
        for source in sources {
            let data = computeDerivatives(for: source).filter({$0.month.compare(date) == .orderedSame})
            if data.count == 1 {
                sum += data[0].carbonValue
            }
        }
        
        return CarbonValue(rawValue: sum)
    }
}
