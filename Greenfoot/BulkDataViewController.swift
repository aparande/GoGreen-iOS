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
    var data: GreenData!
    
    init(withData x:GreenData) {
        data = x
        super.init(style: .plain)
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
        
        let header = Bundle.main.loadNibNamed("AddDataHeader", owner: nil, options: nil)![0] as? AddDataHeaderView
        header?.owner = self
        header?.setInfo(data: self.data)
        self.tableView.tableHeaderView = header
        
        let editButton = IconButton(image: Icon.edit, tintColor: UIColor.white)
        editButton.addTarget(self, action: #selector(beginEdit), for: .touchUpInside)
        navigationItem.rightViews = [editButton]
    }
    
    func beginEdit() {
        self.tableView.setEditing(true, animated: true)
        
        let doneButton = IconButton(image: Icon.check, tintColor: UIColor.white)
        doneButton.addTarget(self, action: #selector(endEdit), for: .touchUpInside)
        navigationItem.rightViews = [doneButton]
    }
    
    func endEdit() {
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
                var keys = Array(self.data.getGraphData().keys)
                keys = keys.sorted(by: {
                    (d1, d2) -> Bool in
                    return d1.compare(d2) == ComparisonResult.orderedAscending
                })
                self.data.removeDataPoint(month: keys[indexPath.row])
                self.tableView.deleteRows(at: [indexPath], with: .right)
            }))
            
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
        }
    }
    
    func updateData(month: String, point: Double, path: IndexPath?) {
        let date = Date.monthFormat(string: month)
        self.data.editDataPoint(month: date, y:point)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.getGraphData().keys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditCell", for: indexPath) as! EditTableViewCell
        cell.owner = self
        cell.indexPath = indexPath
        
        let graphData = data.getGraphData()
        var keys = Array(graphData.keys)
        keys = keys.sorted(by: {
            (d1, d2) -> Bool in
            return d1.compare(d2) == ComparisonResult.orderedAscending
        })
        
        let date = keys[indexPath.row]
        let value = graphData[date]!
        cell.setInfo(attribute: Date.monthFormat(date: date), data: Double(value))
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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
    var owner: UITableViewController!
    
    override func awakeFromNib() {
        addButton.cornerRadius = addButton.frame.height/2
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
        case "Electric":
            dataDescription.text = "Enter how many Kilowatts-Hours of electriicty you have used each month"
            break
        case "Water":
            dataDescription.text = "Enter how many gallons of water you have used each month"
            break
        case "Emissions":
            dataDescription.text = "Enter how many miles you have driven each month"
            break
        case "Gas":
            dataDescription.text = "Enter how much natural gas you have used each month"
            break
        default:
            dataDescription.text = "Enter how many Kilowatts-Hours of electriicty you have used each month"
            break
        }
    }
    
    func textFieldDidChange(textfield: UITextField) {
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
    
    func monthChosen() {
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
        
        
        if let _ = data.getGraphData()[date] {
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
        if data.dataName == "Gas" {
            for (_, value) in data.getGraphData() {
                if value > 10 {
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
        
        data.addDataPoint(month: date, y: conversionFactor * point, save:true)
        
        monthField.text = ""
        pointField.text = ""
        monthToolbarField.text = ""
        pointToolbarField.text = ""
        
        pointField.resignFirstResponder()
        
        var keys = Array(data.getGraphData().keys)
        keys = keys.sorted(by: {
            (d1, d2) in
            return d1.compare(d2) == ComparisonResult.orderedAscending
        })
        
        let path = IndexPath(row: keys.index(of: date)!, section: 0)
        owner.tableView.insertRows(at: [path], with: .automatic)
    }

}
