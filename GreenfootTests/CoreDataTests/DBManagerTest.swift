//
//  DBManagerTest.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 7/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import XCTest
import CoreData
@testable import Greenfoot

class DBManagerTest: CoreDataTest {
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadDefaults() {
        let defaults = UserDefaults.makeClearedInstance()
        
        dbManager = DBManager(container: mockPersistentContainer, defaults: defaults)
        
        XCTAssert(defaults.bool(forKey: DefaultsKeys.LOADED_CORE_DATA_DEFAULTS))
        
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext)
            XCTAssert(sources.count == 2)
        } catch {
            XCTFail()
        }
        
        do {
            let units = try Unit.all(inContext: dbManager.backgroundContext)
            XCTAssert(units.count == 4)
            
            for unit in units {
                if unit.fid != "direct-default" {
                    XCTAssert(unit.conversionsTo?.count == 1)
                }
            }
        } catch {
            XCTFail()
        }
    }

}
