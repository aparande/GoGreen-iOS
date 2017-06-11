//
//  AddEmissionsViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/3/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class AddEmissionsViewController: UITableViewController, DataUpdater {
    let data = GreenfootModal.sharedInstance.data["Emissions"] as! EmissionsData
    var cars:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let editNib = UINib(nibName: "EditDataCell", bundle: nil)
        tableView.register(editNib, forCellReuseIdentifier: "EditCell")
        
        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        navigationItem.backButton.title = "Save"
        navigationItem.backButton.titleLabel?.font = UIFont(name: "DroidSans", size: 20.0)
        navigationItem.backButton.titleColor = UIColor.white
        navigationItem.backButton.tintColor = UIColor.white
        
        let addButton = IconButton(image: Icon.add, tintColor: UIColor.white)
        addButton.addTarget(self, action: #selector(addSection), for: .touchUpInside)
        navigationItem.rightViews = [addButton]
        
        for key in data.carData.keys {
            cars.append(key)
        }
        
        if cars.count == 0 {
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: tableView.bounds.height/2, width: tableView.bounds.width, height: tableView.bounds.height))
            noDataLabel.text = "NO DATA"
            noDataLabel.font = UIFont(name: "Droid Sans", size: 75.0)
            noDataLabel.textColor = Color.grey.base.withAlphaComponent(0.7)
            noDataLabel.textAlignment = .center
            noDataLabel.numberOfLines = 0
            self.tableView.backgroundView = noDataLabel
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //super.viewWillDisappear(true)
        
        data.compileToGraph()
    }
    
    func updateData(month: String, point: Double, path: IndexPath?) {
        if let _ = path {
            let carName = cars[path!.section]
            data.carData[carName]?[month] = Int(point)
        }
    }
    
    func updateAttribute(key: String, value: Int) {
        assertionFailure("Method not implemented because it is not necessary")
    }
    
    func addSection() {
        self.tableView.backgroundView = nil
        let newSectionNum = self.cars.count
        cars.append("Car \(newSectionNum)")
        
        self.tableView.insertSections([newSectionNum], with: .bottom)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditCell", for: indexPath) as! EditTableViewCell
        cell.owner = self
        cell.indexPath = indexPath
        
        let sectionData = data.carData[cars[indexPath.section]]!
        var keys = Array(sectionData.keys)
        keys = keys.sorted(by: {
            (key1, key2) -> Bool in
            let d1 = Date.monthFormat(date: key1)
            let d2 = Date.monthFormat(date: key2)
            return d1.compare(d2) == ComparisonResult.orderedAscending
        })
        
        let date = keys[indexPath.row]
        let value = sectionData[date]!
        cell.setInfo(attribute: date, data: Double(value))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = Bundle.main.loadNibNamed("EmissionHeader", owner: nil, options: nil)![0] as? EmissionHeaderView
        view?.setOwner(owner: self, section: section)
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 76
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return cars.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if let rowData = data.carData[cars[section]] {
            return rowData.count
        } else {
            return 0
        }
    }
}

class EmissionHeaderView: UIView, UITextFieldDelegate {
    @IBOutlet weak var nameField: TextField!
    @IBOutlet weak var mileageField: TextField!
    @IBOutlet weak var addButton: IconButton!
    
    var owner: AddEmissionsViewController!
    var sectionNum:Int!
    
    override func awakeFromNib() {
        addButton.cornerRadius = addButton.frame.height/2
        addButton.backgroundColor = Colors.green
        addButton.image = Icon.add
        addButton.tintColor = UIColor.white
        
        nameField.delegate = self
        mileageField.delegate = self
        
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
    @IBAction func add(_ sender: Any) {
        if nameField.text == "" || mileageField.text == "" {
            let alertView = UIAlertController(title: "Error", message: "Before recording your odometer data, please enter in the name of your car and how many miles per gallon it runs", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: nil)
            return
        }
        
        if !nameField.isUserInteractionEnabled && !mileageField.isUserInteractionEnabled {
            nameField.isUserInteractionEnabled = false
            mileageField.isUserInteractionEnabled = false
        }
        
        let carName = nameField.text!
        let mileage = Int(mileageField.text!)!
        
        owner.cars[sectionNum] = carName
        owner.data.carMileage[carName] = mileage
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.string(from: Date())
        
        if let _ = owner.data.carData[carName] {
            if let _ = owner.data.carData[carName]![date] {
                let alertView = UIAlertController(title: "Error", message: "You can only enter one odometer reader per car each month. Record the next reading next month.", preferredStyle: .alert)
                alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                owner.present(alertView, animated: true, completion: nil)
                return
            } else {
                owner.data.carData[carName]![date] = 1000
            }
        } else {
            owner.data.carData[carName] = [date:1000]
        }
        
        let row = owner.data.carData[carName]!.count-1
        let path = IndexPath(row: row, section: sectionNum)
        
        owner.tableView.insertRows(at: [path], with: .automatic)
    }
    
    func setOwner(owner: AddEmissionsViewController, section: Int) {
        self.owner = owner
        self.sectionNum = section
        
        if owner.cars[section] != "Car \(section)" {
            nameField.text = owner.cars[section]
            mileageField.text = String(describing: owner.data.carMileage[nameField.text!]!)
            
            nameField.isUserInteractionEnabled = false
            mileageField.isUserInteractionEnabled = false
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
