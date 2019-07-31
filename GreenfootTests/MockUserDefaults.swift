//
//  MockUserDefaults.swift
//  GreenfootTests
//
//  Created by Anmol Parande on 7/30/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

extension UserDefaults {
    static func makeClearedInstance(for functionName: StaticString = #function, inFile fileName: StaticString = #file) -> UserDefaults {
        let className = "\(fileName)".split(separator: ".")[0]
        let testName = "\(functionName)".split(separator: "(")[0]
        let suiteName = "com.aparande.gogreen.test.\(className).\(testName)"
        
        let defaults = self.init(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
