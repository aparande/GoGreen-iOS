//
//  ElectricViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/15/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class ElectricViewController: GraphViewController {
    
    override func setDataType() {
        data = greenModal.electricData
        print("Data set to Electric")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let dateOne = formatter.date(from: "01/17")!
        let dateTwo = formatter.date(from: "02/17")!
        let dateThree = formatter.date(from: "03/17")!
        
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateOne, y:10)
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateTwo, y:20)
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateThree, y:20)
    }

}
