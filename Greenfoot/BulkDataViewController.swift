//
//  BulkDataViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/1/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class BulkDataViewController:UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var data: GreenData!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var monthField:TextField!
    @IBOutlet var pointField:TextField!
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var dataDescription: UILabel!
    
    
    var datePicker: UIDatePicker!
    var addedMonths: [Date]!
    var addedPoints: [Double]!
    
    var monthToolbarField: UITextField!
    var pointToolbarField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
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
        
        addedMonths = []
        addedPoints = []
        
        
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
        monthField.inputAccessoryView = nextToolbar
        
        //Create the toolbar for the points field
        let doneToolbar = InputToolbar(left: Icon.cm.close, right: Icon.cm.check, color: Colors.green)
        doneToolbar.leftButton?.target = self
        doneToolbar.leftButton?.action = #selector(resignFirstResponder)
        doneToolbar.rightButton?.target = self
        doneToolbar.rightButton?.action = #selector(addDataPoint(sender:))
        pointToolbarField = doneToolbar.centerField
        pointField.inputAccessoryView = doneToolbar
        
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(resignFirstResponder))
        view.addGestureRecognizer(exitGesture)
        
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
        
        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        navigationItem.backButton.title = "Save"
        navigationItem.backButton.titleLabel?.font = UIFont(name: "DroidSans", size: 20.0)
        navigationItem.backButton.titleColor = UIColor.white
        navigationItem.backButton.tintColor = UIColor.white
        
        self.tableView.isHidden = true
    }
    
    func setDataType(dataObj: GreenData) {
        data = dataObj
    }
    
    //@IBOutlet (probably)
    @IBAction func addDataPoint(sender: AnyObject?) {
        if monthField.text == "" || pointField.text == "" {
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.date(from: monthField.text!)!
        
        if let _ = data.getGraphData()[date] {
            let alertView = UIAlertController(title: "Error", message: "You have already entered in data with this date. If you would like to edit the data, please use the edit screen.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            
            pointField.resignFirstResponder()
            return
        }
        addedMonths.append(date)
        addedPoints.append(Double(pointField.text!)!)
    
        self.tableView.isHidden = false
        
        monthField.text = ""
        pointField.text = ""
        monthToolbarField.text = ""
        pointToolbarField.text = ""
        
        pointField.resignFirstResponder()
        
        //update the table view
        tableView.reloadData()
        tableView.scrollToRow(at: IndexPath(row: addedMonths.count-1, section:0), at: .bottom, animated: true)
    }
    
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(true)
        var conversionFactor = 1.0
        if data.dataName == "Gas" {
            /*
             let unitConversion:(Double) -> Double = {
             given in
             
             if given < 10 {
             return given*1000
             } else {
             return given
             }
             } */
            
            for (_, value) in data.getGraphData() {
                if value > 10 {
                    conversionFactor = 1.0
                    break
                } else {
                    conversionFactor = 1000.0
                }
            }
            
            for point in addedPoints {
                if point > 10 && conversionFactor == 1000.0 {
                    conversionFactor = 1.0
                    break
                } else if conversionFactor != 1.0 {
                    conversionFactor = 1000.0
                }
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        for i in 0..<addedMonths.count {
            if data.dataName == "Emissions" {
                let point = 8.887*addedPoints[i]/Double(data.data["Average MPG"]!)
                data.addDataPoint(month: addedMonths[i], y: point)
            
                let date = formatter.string(from: addedMonths[i])
                data.addToServer(month: date, point: point)
            } else if data.dataName == "Gas" {
                data.addDataPoint(month: addedMonths[i], y: conversionFactor * addedPoints[i])
                
                let date = formatter.string(from: addedMonths[i])
                data.addToServer(month: date, point: conversionFactor * addedPoints[i])
            } else {
                data.addDataPoint(month: addedMonths[i], y: addedPoints[i])
                
                let date = formatter.string(from: addedMonths[i])
                data.addToServer(month: date, point: addedPoints[i])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedMonths.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell")!

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.string(from: addedMonths[indexPath.row])
        
        cell.textLabel!.text = date
        cell.detailTextLabel!.text = "\(addedPoints[indexPath.row])"
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @IBAction func incrementValue(_ sender: Any) {
        pointField.text = "\(stepper.value)"
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
        
        if pointField.text! != "" {
            stepper.value = Double(pointField.text!)!
        }
        
        return super.resignFirstResponder()
    }
    
    func textFieldDidChange(textfield: UITextField) {
        if textfield == pointField {
            pointToolbarField.text = pointField.text
        }
    }
}
