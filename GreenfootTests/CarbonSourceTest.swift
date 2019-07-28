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

class CarbonSourceTest: XCTestCase {
    lazy var managedObjectModel: NSManagedObjectModel = {
        let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle(for: type(of: self))])
        return managedObjectModel!
    }()
    
    lazy var mockPersistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "greenfoot_test", managedObjectModel: self.managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (description, error) in
            precondition(description.type == NSInMemoryStoreType)
            
            if let error = error {
                fatalError("Could not create an in-memory store coordinator \(error)")
            }
        })
        return container
    }()
    
    var dbManager: DBManager!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
        dbManager = DBManager(container: mockPersistentContainer)
        createStubs()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFetchAll() {
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext)
            XCTAssert(sources.count == 3, "Found \(sources.count) sources")
        } catch {
            XCTFail()
        }
    }
    
    func testFetchByCategory() {
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext,
                                               fromCategories: [CarbonSource.SourceCategory.utility])
            for source in sources {
                XCTAssert(source.sourceCategory == CarbonSource.SourceCategory.utility.rawValue)
            }
        } catch {
            XCTFail()
        }
    }
    
    func testFetchByType() {
        do {
            let sources = try CarbonSource.all(inContext: dbManager.backgroundContext,
                                               withTypes: [.electricity, .odometer])
            for source in sources {
                XCTAssert(source.sourceType == CarbonSource.SourceType.electricity.rawValue ||
                            source.sourceType == CarbonSource.SourceType.odometer.rawValue)
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
