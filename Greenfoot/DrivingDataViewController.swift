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
    
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "DrivingTutorial") {
            let alertView = UIAlertController(title: "Entering Driving Data", message: "To calculate your carbon dioxide emissions from driving, add your cars and enter how many miles per gallon each one uses. Then, enter the odometer reading from your cars each month.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Got it", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: {
                defaults.set(true, forKey: "DrivingTutorial")
            })
            return
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
            
            let index = drivingData.indexOfPointForDate(date, inArray: drivingData.carData[carName]!)
            drivingData.updateOdometerReading(forCar: carName, atIndex: index, toValue: point)
        }
    }
    
    override func updateError() {
        let alertView = UIAlertController(title: "Error", message: "Please enter a valid number", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alertView, animated: true, completion: nil)
    }
    
    @objc func addSection() {
        self.tableView.backgroundView = nil
        let newSectionNum = self.cars.count
        cars.append("Car \(newSectionNum)")
        
        self.tableView.insertSections([newSectionNum], with: .bottom)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("DrivingHeader", owner: nil, options: nil)![0] as? DrivingHeaderView
        view?.setOwner(owner: self, section: section)
        sectionHeaders[section] = view
        
        if let _ = view {
            var size = view!.frame.size
            size.height = (UIDevice.current.userInterfaceIdiom == .phone) ? 175 : 200
            view!.frame = CGRect(center: view!.frame.center, size: size)
        }
        
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 76
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return cars.count
    }
    
    @objc override func beginEdit() {
        super.beginEdit()
        
        for (_, view) in sectionHeaders {
            view.beginEdit()
        }
    }
    
    @objc override func endEdit() {
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

                let sectionData = self.dataForSection(indexPath.section)!
                let index = sectionData.count - 1 - indexPath.row
                let date = sectionData[index].month
                
                if sectionData.count == 0 {
                    let carName = self.cars.remove(at: indexPath.section)
                    self.drivingData.carMileage.removeValue(forKey: carName)
                    self.drivingData.carData.removeValue(forKey: carName)
                    self.sectionHeaders.removeValue(forKey: indexPath.section)
                    self.drivingData.deleteCar(carName)
                    self.tableView.deleteSections([indexPath.section], with: .automatic)
                    self.updateHeaders()
                } else {
                    let carName = self.cars[indexPath.section]
                    let index = self.drivingData.indexOfPointForDate(date, inArray: self.drivingData.carData[carName]!)
                    let reading = self.drivingData.carData[carName]?.remove(at: index)
                    self.drivingData.deleteOdometerReading(reading!, forCar: carName)
                    self.drivingData.compileToGraph()
                    self.tableView.deleteRows(at: [indexPath], with: .right)
                }
            }))
            
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            
        }
    }
    
    override func dataForSection(_ section: Int) -> [GreenDataPoint]? {
        return drivingData.carData[cars[section]]
    }
    
    func updateHeaders() {
        var head:[Int:DrivingHeaderView] = [:]
        for i in 0..<cars.count {
            let car = cars[i]
            
            for (_, header) in sectionHeaders {
                if header.car! == car {
                    head[i] = header
                    header.sectionNum = i
                    break
                }
            }
        }
        sectionHeaders = head
    }
}

class DrivingHeaderView: UIView, UITextFieldDelegate {
    @IBOutlet weak var nameField: TextField!
    @IBOutlet weak var mileageField: TextField!
    @IBOutlet weak var addButton: IconButton!
    
    var owner: DrivingDataViewController!
    var sectionNum:Int!
    var car:String?
    
    override func awakeFromNib() {
        addButton.layer.cornerRadius = addButton.frame.height/2
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
        if nameField.text?.removeSpecialChars() == "" || mileageField.text?.removeSpecialChars() == "" {
            let alertView = UIAlertController(title: "Error", message: "Before recording your odometer data, please enter in the name of your car and how many miles per gallon it runs", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: nil)
            return
        }
        
        let carName = nameField.text!.removeSpecialChars()
        
        guard let mileage = Int(mileageField.text!) else {
            let alertView = UIAlertController(title: "Error", message: "Please round to the nearest whole number", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: {
                self.mileageField.text = ""
            })
            return
        }
        
        owner.cars[sectionNum] = carName
        
        owner.drivingData.carMileage[carName] = GreenAttribute(value: mileage, lastUpdated: Date())
        
        if nameField.isUserInteractionEnabled && mileageField.isUserInteractionEnabled {
            //This is when the car is created
            nameField.isUserInteractionEnabled = false
            mileageField.isUserInteractionEnabled = false
            
            mileageField.textColor = Colors.grey
            nameField.textColor = Colors.grey
            
            mileageField.setNeedsDisplay()
            nameField.setNeedsDisplay()
            
            let encodedData = try? JSONEncoder().encode(owner.drivingData.carMileage)
            UserDefaults.standard.set(encodedData, forKey: "MilesData")
            
            owner.drivingData.addCarToServer(carName, describedByPoint: owner.drivingData.carMileage[carName]!)
        }
        
        let dateString = Date.monthFormat(date: Date())
        let date = Date.monthFormat(string: dateString)
        
        if let carData = owner.drivingData.carData[carName] {
            //This is not the first row in the section
            
            //Get the previvous odometer reading
            let lastVal = carData[0].value
            
            //Make sure that the user is not trying to add two points for the same month
            if let _ = owner.drivingData.findPointForDate(date, inArray: owner.drivingData.carData[carName]!) {
                let alertView = UIAlertController(title: "Error", message: "You can only enter one odometer reader per car each month. Record the next reading next month.", preferredStyle: .alert)
                alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                owner.present(alertView, animated: true, completion: nil)
                return
            } else {
                //If there is data for this car and
                let odometerReading = GreenDataPoint(month: date, value: lastVal, dataType: owner.drivingData.dataName, pointType: .odometer)
                owner.drivingData.addOdometerReading(odometerReading, forCar: carName)
            }
        } else {
            //This is the first row in the section
            let odometerReading = GreenDataPoint(month: date, value: 1000, dataType: owner.drivingData.dataName, pointType: .odometer)
            owner.drivingData.addOdometerReading(odometerReading, forCar: carName)
            
            let path = IndexPath(row: 0, section: sectionNum)
            
            owner.tableView.insertRows(at: [path], with: .automatic)
            return
        }
        
        let path = IndexPath(row: 0, section: sectionNum)
        
        owner.tableView.insertRows(at: [path], with: .automatic)
    }
    
    @objc func remove() {
        let alertView = UIAlertController(title: "Are You Sure?", message: "Are you sure you would like to delete all data for this car?", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
            _ in
            //Remove the mileage data, the car data, and the odometer data
            let carName = self.owner.cars.remove(at: self.sectionNum)
            self.owner.sectionHeaders.removeValue(forKey: self.sectionNum)
            self.owner.drivingData.deleteCar(carName)
            self.owner.tableView.deleteSections([self.sectionNum], with: .automatic)
            self.owner.updateHeaders()
        }))
        
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        owner.present(alertView, animated: true, completion: nil)
    }
    
    func setOwner(owner: DrivingDataViewController, section: Int) {
        self.owner = owner
        self.sectionNum = section
        
        if owner.cars[section] != "Car \(section)" {
            car = owner.cars[section]
            nameField.text = car
            
            mileageField.text = String(describing: owner.drivingData.carMileage[nameField.text!]!.value)
            
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
