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
    @IBOutlet var dailyAverageLabel:UILabel!
    
    var fabMenu:FABMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dailyAverageLabel.text = "\(data.averageValue) kWh per Day"
    }
    
    override func reloadData() {
        super.reloadData()
        dailyAverageLabel.text = "\(data.averageValue) kWh per Day"
    }
    
    override func setDataType() {
        data = greenModal.electricData
        print("Data set to Electric")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let dateOne = formatter.date(from: "01/17")!
        let dateTwo = formatter.date(from: "02/17")!
        let dateThree = formatter.date(from: "03/17")!
        
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateOne, y:1001)
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateTwo, y:800)
        GreenfootModal.sharedInstance.electricData.addDataPoint(month:dateThree, y:700)
    }
    
    override func createFABMenu() {
        fabMenu = FABMenu()
        
        let fabButton = FABButton(image: Icon.cm.moreVertical, tintColor: .white)
        fabButton.backgroundColor = Colors.green
        
        let addFabItem = FABMenuItem()
        addFabItem.title = "Add"
        addFabItem.fabButton.image = Icon.cm.add
        addFabItem.fabButton.tintColor = .white
        addFabItem.fabButton.backgroundColor = Colors.green
        addFabItem.fabButton.addTarget(self, action: #selector(bulkAdd), for: .touchUpInside)
        
        let attributeFabItem = FABMenuItem()
        attributeFabItem.title = "Attributes"
        attributeFabItem.fabButton.image = Icon.cm.edit
        attributeFabItem.fabButton.tintColor = .white
        attributeFabItem.fabButton.backgroundColor = Colors.green
        attributeFabItem.fabButton.addTarget(self, action: #selector(attributeAdd), for: .touchUpInside)
        
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [addFabItem, attributeFabItem]
        
        
        self.view.layout(fabMenu).size(CGSize(width: 50, height: 50)).bottom(24).right(24)
    }

    func bulkAdd() {
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        let bvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BulkDataViewController") as! BulkDataViewController
        bvc.setDataType(dataObj: data)
        navigationController?.pushViewController(bvc, animated: true)
    }
    
    func attributeAdd() {
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        let advc = AttributeTableViewController(data: data)
        navigationController?.pushViewController(advc, animated: true)
    }
}
