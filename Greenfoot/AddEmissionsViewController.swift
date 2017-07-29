//
//  DrivingDataViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/3/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import CoreData

class DrivingDataViewController: BulkDataViewController {
    let drivingData: DrivingData
    var cars:[String]
    var sectionHeaders: [Int:DrivingHeaderView]
    
    init(withData x:DrivingData) {
        drivingData = x
        cars = []
        
        for key in drivingData.carData.keys {
            cars.append(key)
        }
        
        sectionHeaders = [:]
        super.init(withData: x)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addButton = IconButton(image: Icon.add, tintColor: UIColor.white)
        addButton.addTarget(self, action: #selector(addSection), for: .touchUpInside)
        navigationItem.rightViews = [addButton]
        
        if cars.count == 0 {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: tableView.bounds.height/2, width: tableView.bounds.width, height: tableView.bounds.height))
            noDataLabel.text = "NO DATA"
            noDataLabel.font = UIFont(name: "Droid Sans", size: 75.0)
            noDataLabel.textColor = Color.grey.base.withAlphaComponent(0.7)
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            self.tableView.backgroundView = noDataLabel
        } else {
            let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
            editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
            navigationItem.rightViews = [editButton, addButton]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        drivingData.compileToGraph()
    }
    
    override func updateData(month: String, point: Double, path: IndexPath?) {
        if let _ = path {
            let carName = cars[path!.section]
            let date = Date.monthFormat(string: month)
            drivingData.carData[carName]?[date] = point
            self.drivingData.updateCoreDataForCar(car: carName, month: date, amount: point)
        }
    }
    
    func addSection() {
        self.tableView.backgroundView = nil
        let newSectionNum = self.cars.count
        cars.append("Car \(newSectionNum)")
        
        self.tableView.insertSections([newSectionNum], with: .bottom)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("DrivingHeader", owner: nil, options: nil)![0] as? DrivingHeaderView
        view?.setOwner(owner: self, section: section)
        sectionHeaders[section] = view
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 76
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return cars.count
    }
    
    override func beginEdit() {
        super.beginEdit()
        
        for (_, view) in sectionHeaders {
            view.beginEdit()
        }
    }
    
    override func endEdit() {
        self.tableView.setEditing(false, animated: true)
        
        for (_, view) in sectionHeaders {
            view.endEdit()
        }
        
        drivingData.compileToGraph()
        
        let addButton = IconButton(image: Icon.add, tintColor: UIColor.white)
        addButton.addTarget(self, action: #selector(addSection), for: .touchUpInside)
        
        if cars.count == 0 {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: tableView.bounds.height/2, width: tableView.bounds.width, height: tableView.bounds.height))
            noDataLabel.text = "NO DATA"
            noDataLabel.font = UIFont(name: "Droid Sans", size: 75.0)
            noDataLabel.textColor = Color.grey.base.withAlphaComponent(0.7)
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            self.tableView.backgroundView = noDataLabel
            
            navigationItem.rightViews = [addButton]
        } else {
            let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
            editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
            navigationItem.rightViews = [editButton, addButton]
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertView = UIAlertController(title: "Are You Sure?", message: "Are you sure you would like to delete this data point?", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
                _ in
                let carName = self.cars[indexPath.section]
                let cell = tableView.cellForRow(at: indexPath) as! EditTableViewCell
                
                let date = Date.monthFormat(string: cell.attributeLabel.text!)
                
                self.drivingData.carData[carName]?.removeValue(forKey: date)
                self.drivingData.deletePointForCar(carName, month: date)
                self.drivingData.compileToGraph()
                self.tableView.deleteRows(at: [indexPath], with: .right)
            }))
            
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            
        }
    }
    
    override func dataForSection(_ section: Int) -> [Date : Double]? {
        return drivingData.carData[cars[section]]
    }
}

class DrivingHeaderView: UIView, UITextFieldDelegate {
    @IBOutlet weak var nameField: TextField!
    @IBOutlet weak var mileageField: TextField!
    @IBOutlet weak var addButton: IconButton!
    
    var owner: DrivingDataViewController!
    var sectionNum:Int!
    
    override func awakeFromNib() {
        addButton.cornerRadius = addButton.frame.height/2
        addButton.backgroundColor = Colors.green
        addButton.image = Icon.add
        addButton.tintColor = UIColor.white
        
        nameField.delegate = self
        mileageField.delegate = self
        
        nameField.dividerActiveColor = Colors.green
        nameField.dividerNormalColor = Colors.green
        nameField.placeholderNormalColor = Colors.green
        nameField.placeholderActiveColor = Colors.green
        nameField.tintColor = Colors.green
        
        mileageField.dividerActiveColor = Colors.green
        mileageField.dividerNormalColor = Colors.green
        mileageField.placeholderNormalColor = Colors.green
        mileageField.placeholderActiveColor = Colors.green
        mileageField.tintColor = Colors.green
        
        let doneToolbar: UIToolbar = UIToolbar()
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Colors.green
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(image: Icon.check, style: .plain, target: mileageField, action: #selector(resignFirstResponder))
        done.tintColor = UIColor.white
        
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        
        self.mileageField.inputAccessoryView = doneToolbar
    }
    
    func beginEdit() {
        UIView.animate(withDuration: 0.5, animations: {
            self.addButton.backgroundColor = Colors.red
            self.addButton.image = Icon.close
        }, completion: nil)
        
        addButton.removeTarget(self, action: #selector(add(_:)), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
    }
    
    func endEdit() {
        UIView.animate(withDuration: 0.5, animations: {
            self.addButton.backgroundColor = Colors.green
            self.addButton.image = Icon.add
        }, completion: nil)
        
        addButton.removeTarget(self, action: #selector(remove), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(add(_:)), for: .touchUpInside)
    }
    
    @IBAction func add(_ sender: Any) {
        if nameField.text == "" || mileageField.text == "" {
            let alertView = UIAlertController(title: "Error", message: "Before recording your odometer data, please enter in the name of your car and how many miles per gallon it runs", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: nil)
            return
        }
        
        let carName = nameField.text!
        let mileage = Int(mileageField.text!)!
        
        owner.cars[sectionNum] = carName
        owner.drivingData.carMileage[carName] = mileage
        
        if nameField.isUserInteractionEnabled && mileageField.isUserInteractionEnabled {
            nameField.isUserInteractionEnabled = false
            mileageField.isUserInteractionEnabled = false
            
            mileageField.textColor = Colors.grey
            nameField.textColor = Colors.grey
            
            mileageField.setNeedsDisplay()
            nameField.setNeedsDisplay()
            
            UserDefaults.standard.set(owner.drivingData.carMileage, forKey: "MilesData")
        }
        
        let dateString = Date.monthFormat(date: Date())
        let date = Date.monthFormat(string: dateString)
        
        guard let sectionData = owner.drivingData.carData[carName] else {
            //This is the first row in the section
            owner.drivingData.carData[carName] = [date:1000]
            owner.drivingData.addPointToCoreData(car: carName, month: date, point: 1000)
            
            let row = owner.drivingData.carData[carName]!.count-1
            let path = IndexPath(row: row, section: sectionNum)
            
            owner.tableView.insertRows(at: [path], with: .automatic)
            return
        }
        
        var keys = Array(sectionData.keys)
        keys = keys.sorted(by: {
            (key1, key2) -> Bool in
            return key1.compare(key2) == ComparisonResult.orderedDescending
        })
        
        let lastVal = owner.drivingData.carData[carName]![keys[0]]!
        
        if let _ = owner.drivingData.carData[carName] {
            if let _ = owner.drivingData.carData[carName]![date] {
                let alertView = UIAlertController(title: "Error", message: "You can only enter one odometer reader per car each month. Record the next reading next month.", preferredStyle: .alert)
                alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                owner.present(alertView, animated: true, completion: nil)
                return
            } else {
                owner.drivingData.carData[carName]![date] = lastVal
            }
        } else {
            owner.drivingData.carData[carName] = [date:lastVal]
        }
        
        owner.drivingData.addPointToCoreData(car: carName, month: date, point: lastVal)
        
        let row = owner.drivingData.carData[carName]!.count-1
        let path = IndexPath(row: row, section: sectionNum)
        
        owner.tableView.insertRows(at: [path], with: .automatic)
    }
    
    func remove() {
        let alertView = UIAlertController(title: "Are You Sure?", message: "Are you sure you would like to delete all data for this car?", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            _ in
            //Remove the mileage data, the car data, and the odometer data
            let carName = self.owner.cars.remove(at: self.sectionNum)
            self.owner.drivingData.carMileage.removeValue(forKey: carName)
            self.owner.drivingData.carData.removeValue(forKey: carName)
            self.owner.sectionHeaders.removeValue(forKey: self.sectionNum)
            self.owner.drivingData.deleteCar(carName)
            self.owner.tableView.deleteSections([self.sectionNum], with: .automatic)
        }))
        
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        owner.present(alertView, animated: true, completion: nil)
    }
    
    func setOwner(owner: DrivingDataViewController, section: Int) {
        self.owner = owner
        self.sectionNum = section
        
        if owner.cars[section] != "Car \(section)" {
            nameField.text = owner.cars[section]
            mileageField.text = String(describing: owner.drivingData.carMileage[nameField.text!]!)
            
            nameField.isUserInteractionEnabled = false
            mileageField.isUserInteractionEnabled = false
            
            mileageField.textColor = Colors.grey
            nameField.textColor = Colors.grey
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if nameField.text != "" {
            owner.cars[sectionNum] = nameField.text!
        }
        
        textField.resignFirstResponder()
        return true
    }
}
