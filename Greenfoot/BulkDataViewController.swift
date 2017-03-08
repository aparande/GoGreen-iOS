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
    
    @IBOutlet var monthField:UITextField!
    
    @IBOutlet var pointField:UITextField!
    @IBOutlet weak var stepper: UIStepper!
    
    var datePicker: UIDatePicker!
    
    var addedMonths: [Date]!
    var addedPoints: [Double]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        monthField.delegate = self
        pointField.delegate = self
        
        addedMonths = []
        addedPoints = []
        
        let logo = UIImageView(image: UIImage(named: "Plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = Colors.green
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(monthChosen), for: .valueChanged)
        //datePicker.addTarget(monthField, action: #selector(resignFirstResponder), for: .touchUpInside)
        monthField.inputView = datePicker
        
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(resignFirstResponder))
        view.addGestureRecognizer(exitGesture)
    }
    
    func setDataType(dataObj: GreenData) {
        data = dataObj
    }
    
    //@IBOutlet (probably)
    @IBAction func addDataPoint(sender: AnyObject?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.date(from: monthField.text!)!
        addedMonths.append(date)
        addedPoints.append(Double(pointField.text!)!)
    
        monthField.text = ""
        pointField.text = ""
        
        //update the table view
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(true)
        for i in 0..<addedMonths.count {
            data.addDataPoint(month: addedMonths[i], y: addedPoints[i])
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
    }
    
    override func resignFirstResponder() -> Bool {
        monthField.resignFirstResponder()
        pointField.resignFirstResponder()
        
        if pointField.text! != "" {
            stepper.value = Double(pointField.text!)!
        }
        
        return super.resignFirstResponder()
    }
}
