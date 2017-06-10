//
//  TutorialPageViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/11/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import ScrollableGraphView
import Material

protocol TutorialPageDelegate {
    func skipPage()
}

class TutorialPageViewController: UIViewController, UITextFieldDelegate  {

    var delegate:TutorialPageDelegate!
    var hasAttributes:Bool!
    var isFinal: Bool!
    
    //Normal View Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var slideTitleLabel: UILabel!
    @IBOutlet weak var slideDescriptionLabel: UILabel!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet weak var skipButton: UIButton!
    //Normal View Variables
    var dataType:String!
    var icon:UIImage!
    var slideDescription: String!
    
    //Importer View Outlet Variables
    var importerView: UIView?
    @IBOutlet weak var monthField: TextField!
    @IBOutlet weak var amountField: TextField!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var graph: ScrollableGraphView!
    @IBOutlet weak var iconDataImageView: UIImageView!
    @IBOutlet weak var closeButton: IconButton!
    //Importer View Variables
    var datePicker: UIDatePicker!
    var monthToolbarField: UITextField!
    var pointToolbarField: UITextField!
    var addedMonths: [Date] = []
    var addedPoints: [Double] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        iconImageView.image  = icon
        slideTitleLabel.text = dataType
        slideDescriptionLabel.text = slideDescription
        
        slideTitleLabel.sizeToFit()
        slideDescriptionLabel.sizeToFit()
        
        if !hasAttributes {
            skipButton.isHidden = true
            goButton.removeTarget(self, action: #selector(revealDataAdder), for: .touchUpInside)
            goButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let greenData = GreenfootModal.sharedInstance.data[dataType] else {
            return
        }
        
        var conversionFactor = 1.0
        if dataType == "Gas" {
            /*
            let unitConversion:(Double) -> Double = {
                given in
                
                if given < 10 {
                    return given*1000
                } else {
                    return given
                }
            } */
            
            for point in addedPoints {
                if point > 10 {
                    conversionFactor = 1.0
                    break
                } else {
                    conversionFactor = 1000.0
                }
            }
        }
        
        if addedPoints.count != 0 {
            for i in 0...addedMonths.count-1 {
                greenData.addDataPoint(month: addedMonths[i], y: conversionFactor * addedPoints[i])
            }
        }
    }
    
    @IBAction func revealDataAdder() {
        if let _ = importerView {
            importerView!.frame = importerView!.frame.offsetBy(dx: 0, dy: self.view.bounds.size.height)
            
            let resultFrame = self.view.bounds
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration(1.0)
            UIView.setAnimationDelay(0.25)
            UIView.setAnimationCurve(.easeOut)
            
            importerView!.frame = resultFrame
            
            UIView.commitAnimations()
            return
        }
        importerView = Bundle.main.loadNibNamed("AddDataTutorial", owner: self, options: nil)![0] as? UIView
        
        importerView!.frame = importerView!.frame.offsetBy(dx: 0, dy: self.view.bounds.size.height)
        
        designGraph()
        //graph.set(data: [0.0, 0.0, 0.0, 0.0], withLabels: ["2/17", "3/17", "4/17", "5/17"])
        
        iconDataImageView.image = icon
        
        self.view.addSubview(importerView!)
        
        let resultFrame = self.view.bounds
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.0)
        UIView.setAnimationDelay(0.25)
        UIView.setAnimationCurve(.easeOut)
        
        importerView!.frame = resultFrame
        
        UIView.commitAnimations()
        
        monthField.delegate = self
        amountField.delegate = self
        
        amountField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        monthField.textColor = UIColor.white
        amountField.textColor = UIColor.white
        
        monthField.placeholderNormalColor = UIColor.white
        monthField.placeholderActiveColor = UIColor.white
        monthField.dividerNormalColor = UIColor.white
        monthField.dividerActiveColor = UIColor.white
        
        amountField.placeholderNormalColor = UIColor.white
        amountField.placeholderActiveColor = UIColor.white
        amountField.dividerNormalColor = UIColor.white
        amountField.dividerActiveColor = UIColor.white
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(monthChosen), for: .valueChanged)
        datePicker.maximumDate = Date()
        monthField.inputView = datePicker
        
        //Create a toolbar for the month field
        let nextToolbar = InputToolbar(left: Icon.cm.close, right: "Next", color: Colors.green)
        nextToolbar.leftButton?.target = self
        nextToolbar.leftButton?.action = #selector(resignFirstResponder)
        nextToolbar.rightButton?.target = self.amountField
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
        self.amountField.inputAccessoryView = doneToolbar
        
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(resignFirstResponder))
        importerView!.addGestureRecognizer(exitGesture)
        
        self.closeButton.image = Icon.cm.close
        self.closeButton.tintColor = UIColor.white
    }
    
    @IBAction func addDataPoint(sender: AnyObject?) {
        if amountField.text == "" || monthField.text == "" {
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.date(from: monthField.text!)!
        
        if addedMonths.contains(date) {
            let alertView = UIAlertController(title: "Error", message: "You have already entered in data with this date. If you would like to edit the data, please use the edit screen.", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            
            amountField.resignFirstResponder()
            return
        }
        
        addedMonths.append(date)
        addedPoints.append(Double(amountField.text!)!)
        
        monthField.text = ""
        amountField.text = ""
        monthToolbarField.text = ""
        pointToolbarField.text = ""
        
        //update the graph view
        updateGraphView()
        amountField.resignFirstResponder()
    }
    
    func updateGraphView() {
        var labels: [String] = []
        var points: [Double] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        for i in 0..<addedMonths.count-1 {
            var locMin = i
            var min = addedMonths[i]
            for k in (i+1)..<addedMonths.count {
                if min.compare(addedMonths[k]) == ComparisonResult.orderedDescending {
                    locMin = k
                    min = addedMonths[k]
                }
            }
            let tempMonth = addedMonths[i]
            let tempPoint = addedPoints[i]
            
            addedMonths[i] = min
            addedMonths[locMin] = tempMonth
            
            addedPoints[i] = addedPoints[locMin]
            addedPoints[locMin] = tempPoint
        }
        
        addedMonths.sort(by: { (date1, date2) -> Bool in
            return date1.compare(date2) == ComparisonResult.orderedAscending })
        
        for i in 0...addedMonths.count-1 {
            points.append(addedPoints[i])
            labels.append(formatter.string(from: addedMonths[i]))
        }
        
        if points.count == 0 {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
            
            graph.set(data: points, withLabels: labels)
            graph.layoutSubviews()
            
            if graph.contentSize.width > graph.frame.width {
                graph.setContentOffset(CGPoint(x:graph.contentSize.width - graph.frame.width + 40.0, y:0), animated: true)
            }
        }
    }
    
    func designGraph() {
        graph.backgroundFillColor = Colors.darkGreen
        graph.backgroundColor = Colors.darkGreen
        graph.lineColor = UIColor.clear
        
        graph.shouldDrawBarLayer = true
        graph.barColor = UIColor.white.withAlphaComponent(0.5)
        graph.shouldDrawDataPoint = false
        graph.barLineColor = UIColor.clear
        
        graph.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        graph.referenceLineColor = UIColor.white.withAlphaComponent(0.5)
        graph.referenceLineLabelColor = UIColor.white
        graph.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
        
        graph.shouldAutomaticallyDetectRange = true
        graph.shouldAdaptRange = true
        graph.shouldRangeAlwaysStartAtZero = true
        graph.clipsToBounds = true
        graph.direction = .leftToRight
        
        graph.cornerRadius = 10
    }
    
    @IBAction func incrementData(_ sender: Any) {
        amountField.text = "\(stepper.value)"
        textFieldDidChange(textfield: amountField)
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
        amountField.resignFirstResponder()
        
        monthField.tintColor = UIColor.white
        amountField.tintColor = UIColor.white
        
        if amountField.text! != "" {
            stepper.value = Double(amountField.text!)!
        }
        
        return super.resignFirstResponder()
    }
    
    func setValues(title: String, description: String, icon: UIImage, isEditable:Bool) {
        dataType = title
        slideDescription = description
        self.icon = icon
        hasAttributes = isEditable
    }
    
    @IBAction func skip(_ sender: Any) {
        delegate.skipPage()
    }
    
    @IBAction func closeDataImporter(_ sender: Any) {
        let _ = self.resignFirstResponder()
        
        let endFrame = importerView!.frame.offsetBy(dx: 0, dy: self.view.bounds.size.height+25)
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.0)
        UIView.setAnimationDelay(0.25)
        UIView.setAnimationCurve(.easeOut)
        
        importerView!.frame = endFrame
        
        UIView.commitAnimations()
    }
    
    func textFieldDidChange(textfield: UITextField) {
        if textfield == amountField {
            pointToolbarField.text = amountField.text
        }
    }
}
