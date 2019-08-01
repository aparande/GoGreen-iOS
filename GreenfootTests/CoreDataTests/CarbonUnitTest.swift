//
//  UnitTest.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 7/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import XCTest
@testable import Greenfoot

class CarbonUnitTest: CoreDataTest {
    
    func testCreateFromJSON() {
        let intJson:[String:Any] = ["name": "Int Test Unit",
                                    "sourceType": 1,
                                    "fid": "Test Unit 1"]
        let intUnit = CarbonUnit(inContext: dbManager.backgroundContext, fromJson: intJson)
        XCTAssertNotNil(intUnit)
    }
}
