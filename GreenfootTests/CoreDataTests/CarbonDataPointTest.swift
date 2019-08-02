//
//  CarbonDataPointTest.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 7/31/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import XCTest
@testable import Greenfoot

class CarbonDataPointTest: CoreDataTest {
    func testCreate() {
        do {
            let electricSource = try CarbonSource.all(inContext: dbManager.backgroundContext, withTypes: [.electricity]).first
            XCTAssertNotNil(electricSource)
            
            let unitRequest = CarbonUnit.fetchAllRequest
            unitRequest.predicate = NSPredicate(format: "(%K = %@) AND (%K = %@)", argumentArray: ["sourceType", electricSource!.sourceType.rawValue, "fid", "electric-default"])
            let unit = try dbManager.backgroundContext.fetch(unitRequest).first
            XCTAssertNotNil(unit)
            
            let dataPoint = CarbonDataPoint(inContext: dbManager.backgroundContext, source: electricSource!, unit: unit!, month: NSDate(), value: 500)
            
            print(electricSource)
            
            XCTAssertNotNil(dataPoint)
            XCTAssert(dataPoint?.carbonValue == 616.4)
            
            let sourceData = electricSource?.points
            
            XCTAssert(sourceData?.count == 1) //The Reference
        } catch {
            XCTFail()
        }
        
    }
}
