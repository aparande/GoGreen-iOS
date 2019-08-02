//
//  CarbonReference+CoreDataClass.swift
//  Greenfoot
//
//  Created by Anmol Parande on 7/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CarbonReference)
public class CarbonReference: CarbonDataPoint {

}

extension CarbonReference {
    @objc
    public enum Level: Int16 {
        case country = 0,
            state = 1,
            city = 2
    }
}
