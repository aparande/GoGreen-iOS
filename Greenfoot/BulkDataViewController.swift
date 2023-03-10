//
//  BulkDataViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/1/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class BulkDataViewController: UITableViewController, DataUpdater {
    let data: GreenData
    
    init(withData x:GreenData) {
        data = x
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        if self == self.navigationController?.viewControllers[0] {
            let backButton = IconButton()
            backButton.title = "Save"
            backButton.titleLabel?.font = UIFont(name: "DroidSans", size: 20.0)
            backButton.titleColor = UIColor.white
            backButton.tintColor = UIColor.white
            backButton.addTarget(self, action: #selector(returnToTutorial), for: .touchUpInside)
            navigationItem.leftViews = [backButton]
        }
        
        if data.dataName != "Driving" {
            let header = Bundle.main.loadNibNamed("AddDataHeader", owner: nil, options: nil)![0] as? AddDataHeaderView
            header?.owner = self
            header?.setInfo(data: self.data)
            self.tableView.tableHeaderView = header
            
            let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
            editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
            navigationItem.rightViews = [editButton]
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let headerView = self.tableView.tableHeaderView {
            if headerView.frame.height != 150 {
                let headerFrame = CGRect(origin: CGPoint.zero, size: CGSize(width: self.tableView.frame.width, height: 150))
                headerView.frame = headerFrame
                self.tableView.tableHeaderView = headerView
            }
        }
    }
    
    @objc func returnToTutorial() {
        self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func beginEdit() {
        self.tableView.setEditing(true, animated: true)
        
        let doneButton = IconButton(image: Icon.check, tintColor: UIColor.white)
        doneButton.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        navigationItem.rightViews = [doneButton]
    }
    
    @objc func endEdit() {
        self.tableView.setEditing(false, animated: true)
        
        let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
        editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        navigationItem.rightViews = [editButton]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertView = UIAlertController(title: "Are You Sure?", message: "Are you sure you would like to delete this data point?", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: {
                _ in
                let sectionData = self.dataForSection(indexPath.section)!
                let index = sectionData.count - 1 - indexPath.row
                
                self.data.removeDataPoint(atIndex: index, fromServer: true)
                self.tableView.deleteRows(at: [indexPath], with: .right)
            }))
            
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
        }
    }
    
    func updateData(month: String, point: Double, path: IndexPath?) {
        if let indexPath = path {
            let index = self.dataForSection(indexPath.section)!.count - 1 - indexPath.row
            self.data.editDataPoint(atIndex: index, toValue: point)
        }
    }
    
    func updateError() {
        let alertView = UIAlertController(title: "Error", message: "Please enter a valid number", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alertView, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowData = dataForSection(section) {
            return rowData.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditCell", for: indexPath) as! EditTableViewCell
        cell.owner = self
        cell.indexPath = indexPath
        
        let sectionData = dataForSection(indexPath.section)!
        //The data is ordered with increasing date, so to see most recent dates first, traverse the array backwards
        let index = sectionData.count - 1 - indexPath.row
        let date = sectionData[index].month
        let value = sectionData[index].value
        
        if data.dataName == "Driving" && index - 1 >= 0 {
            let prevValue = sectionData[index-1].value
            cell.setInfo(attribute: Date.monthFormat(date: date), data: Double(value), lowerBound: prevValue, upperBound: nil)
        } else {
            cell.setInfo(attribute: Date.monthFormat(date: date), data: Double(value), lowerBound: nil, upperBound: nil)
        }
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //This method can be overriden in the subclass so multiple sections can be supported
    func dataForSection(_ section: Int) -> [GreenDataPoint]? {
        return data.getGraphData()
    }
}

class AddDataHeaderView: UIView, UITextFieldDelegate {
    @IBOutlet var monthField:TextField!
    @IBOutlet var pointField:TextField!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var dataDescription: UILabel!
    @IBOutlet weak var addButton: IconButton!
    
    var datePicker: UIDatePicker!
    var monthToolbarField: UITextField!
    var pointToolbarField: UITextField!
    
    var data:GreenData!
    var owner: BulkDataViewController!
    
    override func awakeFromNib() {
        addButton.layer.cornerRadius = addButton.frame.height/2
        addButton.backgroundColor = Colors.green
        addButton.image = Icon.add
        addButton.tintColor = UIColor.white
        
        monthField.delegate = self
        pointField.delegate = self
        
        monthField.dividerActiveColor = Colors.green
        monthField.dividerNormalColor = Colors.green
        monthField.placeholderNormalColor = Colors.green
        monthField.placeholderActiveColor = Colors.green
        monthField.tintColor = Colors.green
        
        pointField.dividerActiveColor = Colors.green
        pointField.dividerNormalColor = Colors.green
        pointField.placeholderNormalColor = Colors.green
        pointField.placeholderActiveColor = Colors.green
        pointField.tintColor = Colors.green
        
        pointField.addTarget(self, action: #selector(textFieldDidChange(textfield:)), for: .editingChanged)
        
        //Create the DatePicker to be the input for the month field
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(monthChosen), for: .valueChanged)
        datePicker.maximumDate = Date()
        monthField.inputView = datePicker
        
        //Create a toolbar for the month field
        let nextToolbar = InputToolbar(left: Icon.cm.close, right: "Next", color: Colors.green)
        nextToolbar.leftButton?.target = self
        nextToolbar.leftButton?.action = #selector(resignFirstResponder)
        nextToolbar.rightButton?.target = self.pointField
        nextToolbar.rightButton?.action = #selector(becomeFirstResponder)
        monthToolbarField = nextToolbar.centerField
        monthToolbarField.text = Date.monthFormat(date: Date())
        monthField.inputAccessoryView = nextToolbar
        
        //Create the toolbar for the points field
        let doneToolbar = InputToolbar(left: Icon.cm.close, right: Icon.cm.check, color: Colors.green)
        doneToolbar.leftButton?.target = self
        doneToolbar.leftButton?.action = #selector(resignFirstResponder)
        doneToolbar.rightButton?.target = self
        doneToolbar.rightButton?.action = #selector(addDataPoint(sender:))
        pointToolbarField = doneToolbar.centerField
        pointField.inputAccessoryView = doneToolbar
    }
    
    func setInfo(data: GreenData) {
        self.data = data
        
        iconImageView.image = data.icon
        switch data.dataName {
        case GreenDataType.electric.rawValue:
            dataDescription.text = "Enter how many Kilowatts-Hours of electricty you have used each month"
            break
        case GreenDataType.water.rawValue:
            dataDescription.text = "Enter how many gallons of water you have used each month"
            break
        case GreenDataType.driving.rawValue:
            dataDescription.text = "Enter how many miles you have driven each month"
            break
        case GreenDataType.gas.rawValue:
            dataDescription.text = "Enter how much natural gas you have used each month"
            break
        default:
            dataDescription.text = "Enter how many Kilowatts-Hours of electricty you have used each month"
            break
        }
    }
    
    @objc func textFieldDidChange(textfield: UITextField) {
        if textfield == pointField {
            pointToolbarField.text = pointField.text
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == monthField {
            monthField.text = Date.monthFormat(date: Date())
        }
        return true
    }
    
    @objc func monthChosen() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.string(from: datePicker.date)
        monthField.text! = date
        monthToolbarField.text = date
    }
    
    override func resignFirstResponder() -> Bool {
        monthField.resignFirstResponder()
        pointField.resignFirstResponder()
        
        
        return super.resignFirstResponder()
    }
    
    @IBAction func addDataPoint(sender: AnyObject?) {
        if monthField.text == "" || pointField.text == "" {
            return
        }
        
        let date = Date.monthFormat(string: monthField.text!)
        
        
        if let _ = data.findPointForDate(date, ofType: .regular) {
            let alertView = UIAlertController(title: "Error", message: "You have already entered in data with this date. If you would like to edit the data, please use the edit screen.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: nil)
            
            pointField.resignFirstResponder()
            return
        }
        
        guard let point = Double(pointField.text!) else {
            let alertView = UIAlertController(title: "Error", message: "Please enter a valid number", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            owner.present(alertView, animated: true, completion: nil)
            return
        }
        
        var conversionFactor = 1.0
        if data.dataName == GreenDataType.gas.rawValue {
            for dataPoint in data.getGraphData() {
                if dataPoint.value > 10 {
                    conversionFactor = 1.0
                    break
                } else {
                    conversionFactor = 1000.0
                }
            }
            
            if point > 10 && conversionFactor == 1000.0 {
                conversionFactor = 1.0
            } else if conversionFactor != 1.0 {
                conversionFactor = 1000.0
            }
        }
        
        let dataPoint = GreenDataPoint(month: date, value: conversionFactor * point, dataType: data.dataName, lastUpdated: Date())
        data.addDataPoint(point: dataPoint, save:true, upload: true)
        
        monthField.text = ""
        pointField.text = ""
        monthToolbarField.text = ""
        pointToolbarField.text = ""
        
        pointField.resignFirstResponder()
        
        owner.tableView.reloadSections([0], with: .fade)
        
        GreenfootModal.sharedInstance.queueReminder(dataType: GreenDataType(rawValue: data.dataName)!)
    }

}
