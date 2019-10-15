//
//  DBManager+Defaults.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

extension DBManager {
    private func loadPlist(named name: String) -> [String:AnyObject] {
        var plistFormat = PropertyListSerialization.PropertyListFormat.xml
        var data: [String:AnyObject] = [:]
        
        guard let path = Bundle.main.path(forResource: name, ofType: "plist") else { print("Could not find plist named '\(name)'"); return data}
        guard let xml = FileManager.default.contents(atPath: path) else { print("Could not load file from path: \(path)"); return data}
        
        do {
            data = try PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: &plistFormat) as! [String:AnyObject]
        } catch  {
            print("Error reading \(name).plist: \(error), format: \(plistFormat)")
        }
        
        return data
    }
    
    func loadDefaults() {
        print("Loading Defaults")
        
        //let defaults = loadPlist(named: "defaults")
        
        /*
        guard let sourcesData = defaults["sources"] as? [[String: AnyObject]] else { return }
        guard let unitsData = defaults["units"] as? [[String: AnyObject]] else { return }
        guard let referencesData = defaults["references"] as? [String: [String: AnyObject]] else { return }
        guard let conversionsData = defaults["conversions"] as? [String: [String: AnyObject]] else { return } */
        
        FirebaseUtils.loadDefaultUnits(intoContext: self.backgroundContext) { (units) in
            print("Loaded \(units.map({"\($0.id)-\($0.name)"}))")
            self.save()
        }
        
        //let sources = createCoreDataObject(CarbonSource.self, fromData: sourcesData)
        //let units = createCoreDataObject(CarbonUnit.self, fromData: unitsData)
        //let conversions = createConversions(forUnits: units, usingData: conversionsData)
        //let references = createReferences(usingData: referencesData, forSources: sources, withUnits: units)
    }
    
    private func createCoreDataObject<T:CoreJsonObject>(_ Obj: T.Type, fromData data: [[String:AnyObject]]) -> [T] {
        var objs: [T] = []
        for objData in data {
            guard let o = T(inContext: self.backgroundContext, fromJson: objData) else {continue}
            objs.append(o)
        }
        return objs
    }
    
    private func createConversions(forUnits units: [CarbonUnit], usingData data: [String: [String:AnyObject]]) -> [Conversion] {
        var idMap: [String:CarbonUnit] = [:]
        for unit in units {
            guard let id = unit.id else { continue }
            idMap[id] = unit
        }
        
        var conversions:[Conversion] = []
        
        for sourceId in idMap.keys {
            guard let conversionData = data[sourceId] else {continue}
            guard let destinations = conversionData["destinations"] as? [[String:AnyObject]] else { continue }
            for dest in destinations {
                guard let destId = dest["dest"] as? String else { continue }
                guard let factor = dest["factor"] as? Double else { continue }
                
                let conversion = Conversion(context: self.backgroundContext)
                conversion.source = idMap[sourceId]!
                conversion.dest = idMap[destId]!
                conversion.factor = factor
                
                conversions.append(conversion)
            }
        }
        
        return conversions
    }
    
    private func createReferences(usingData data: [String: [String:AnyObject]],
                                    forSources sources:[CarbonSource],
                                    withUnits units:[CarbonUnit]) -> [CarbonReference] {
        var idMap: [String:CarbonUnit] = [:]
        for unit in units {
            guard let id = unit.id else { continue }
            idMap[id] = unit
        }
        
        var references: [CarbonReference] = []
        
        for source in sources {
            guard let referenceData = data[String(source.sourceType.rawValue)] else { continue }
            
            guard let name = referenceData["name"] as? String else { continue }
            guard let rawValue = referenceData["rawValue"] as? Double else { continue }
            guard let unit = idMap[referenceData["unit"] as! String] else { continue }
            guard let level = CarbonReference.Level(rawValue: Int16(referenceData["level"] as! Int)) else { continue }
            
            guard let reference = CarbonReference(inContext: backgroundContext,
                                                  name: name,
                                                  source: source,
                                                  unit: unit,
                                                  value: rawValue,
                                                  level: level) else { continue }
            
            references.append(reference)
        }
        
        return references
    }
}
