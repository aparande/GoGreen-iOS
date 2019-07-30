//
//  CarbonSourceTest.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 7/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import XCTest
import CoreData
@testable import Greenfoot

class CarbonSourceTest: CoreDataTest {
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        flush()
    }
    
    func testCreateFromJson() {
        let intJson:[String:Any] = ["name": "Int Test Source",
                                     "sourceCategory": 0,
                                     "sourceType": 1]
        let intSource = CarbonSource(inContext: dbManager.backgroundContext, fromJson: intJson)
        XCTAssertNotNil(intSource)
    }

    func testFetchAll() {
        createStubs()
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext)
            XCTAssert(sources.count == 3, "Found \(sources.count) sources")
        } catch {
            XCTFail()
        }
    }
    
    func testFetchByCategory() {
        createStubs()
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext,
                                               fromCategories: [CarbonSource.SourceCategory.utility])
            for source in sources {
                XCTAssert(source.sourceCategory == CarbonSource.SourceCategory.utility)
            }
        } catch {
            XCTFail()
        }
    }
    
    func testFetchByType() {
        createStubs()
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext,
                                               withTypes: [.electricity, .odometer])
            for source in sources {
                XCTAssert(source.sourceType == CarbonSource.SourceType.electricity ||
                            source.sourceType == CarbonSource.SourceType.odometer)
            }
        } catch {
            XCTFail()
        }
    }
    
    private func createStubs() {
        dbManager.createCarbonSource(name: "Electricity", category: .utility, type: .electricity)
        dbManager.createCarbonSource(name: "Gas", category: .utility, type: .gas)
        dbManager.createCarbonSource(name: "Car One", category: .travel, type: .odometer)
    }
    
    private func flush() {
        let sources = try! CarbonSource.all(inContext: dbManager.backgroundContext)
        for source in sources {
            dbManager.backgroundContext.delete(source)
        }
    }
}

public extension NSManagedObject {
    convenience init(context: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: context)!
        self.init(entity: entity, insertInto: context)
    }
}
