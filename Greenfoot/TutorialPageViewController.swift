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
    var importerView: UIView!
    @IBOutlet weak var monthField: UITextField!
    @IBOutlet weak var amountField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var graph: ScrollableGraphView!
    @IBOutlet weak var iconDataImageView: UIImageView!
    //Importer View Variables
    var datePicker: UIDatePicker!
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
            goButton.isHidden = true
            skipButton.isHidden = true
        }
        
        if isFinal {
            goButton.isHidden = false
            goButton.removeTarget(self, action: #selector(revealDataAdder), for: .touchUpInside)
            goButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let greenData = GreenfootModal.sharedInstance.data[dataType] else {
            return
        }
        
        if addedPoints.count != 0 {
            for i in 0...addedMonths.count-1 {
                greenData.addDataPoint(month: addedMonths[i], y: addedPoints[i])
            }
        }
    }
    
    @IBAction func revealDataAdder() {
        importerView = Bundle.main.loadNibNamed("AddDataTutorial", owner: self, options: nil)![0] as! UIView
        
        importerView.frame = importerView.frame.offsetBy(dx: 0, dy: self.view.bounds.size.height)
        
        designGraph()
        graph.set(data: [0.0, 0.0, 0.0, 0.0], withLabels: ["2/17", "3/17", "4/17", "5/17"])
        
        iconDataImageView.image = icon
        
        self.view.addSubview(importerView)
        
        let resultFrame = self.view.bounds
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1.0)
        UIView.setAnimationDelay(0.5)
        UIView.setAnimationCurve(.easeOut)
        
        importerView.frame = resultFrame
        
        UIView.commitAnimations()
        
        monthField.delegate = self
        amountField.delegate = self
        
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(monthChosen), for: .valueChanged)
        monthField.inputView = datePicker
        
        let exitGesture = UITapGestureRecognizer(target: self, action: #selector(resignFirstResponder))
        importerView.addGestureRecognizer(exitGesture)
    }
    
    @IBAction func addDataPoint(sender: AnyObject?) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.date(from: monthField.text!)!
        addedMonths.append(date)
        addedPoints.append(Double(amountField.text!)!)
        
        monthField.text = ""
        amountField.text = ""
        
        //update the graph view
        updateGraphView()
    }
    
    func updateGraphView() {
        var labels: [String] = []
        var points: [Double] = []
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        
        for i in 0...addedMonths.count-1 {
            points.append(addedPoints[i])
            labels.append(formatter.string(from: addedMonths[i]))
        }
        
        if points.count == 0 {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
            
            designGraph()
            graph.set(data: points, withLabels: labels)
        }
    }
    
    func designGraph() {
        graph.backgroundFillColor = UIColor(red: 45/255, green: 191/255, blue: 122/255, alpha: 1.0)

        graph.lineWidth = 1
        //graph.lineColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
        graph.lineColor = UIColor.white
        graph.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        graph.dataPointSpacing = 80
        graph.dataPointSize = 2
        graph.dataPointFillColor = Color.white
        
        graph.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        graph.referenceLineColor = UIColor.white.withAlphaComponent(0.5)
        graph.referenceLineLabelColor = UIColor.white
        graph.dataPointLabelColor = UIColor.white.withAlphaComponent(0.5)
        
        graph.shouldAutomaticallyDetectRange = true
        graph.clipsToBounds = true
    }
    
    @IBAction func incrementData(_ sender: Any) {
        amountField.text = "\(stepper.value)"
    }
    
    func monthChosen() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/yy"
        let date = formatter.string(from: datePicker.date)
        monthField.text! = date
    }
    
    override func resignFirstResponder() -> Bool {
        monthField.resignFirstResponder()
        amountField.resignFirstResponder()
        
        monthField.dividerColor = UIColor.white
        amountField.dividerColor = UIColor.white
        
        if amountField.text! != "" {
            stepper.value = Double(amountField.text!)!
        }
        
        return super.resignFirstResponder()
    }
    
    func setValues(title: String, description: String, icon: UIImage, isEditable:Bool, isLast:Bool) {
        dataType = title
        slideDescription = description
        self.icon = icon
        hasAttributes = isEditable
        isFinal = isLast
    }
    
    @IBAction func skip(_ sender: Any) {
        delegate.skipPage()
    }
}
