//
//  AttributeTableViewCell.swift
//  Greenfoot
//
//  Created by Anmol Parande on 3/7/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class AttributeDescriptionTableViewCell: UITableViewCell {
    @IBOutlet weak var descriptionLabel: UILabel!
}

class AttributeTableViewCell: UITableViewCell {
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var dataPointLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    var owner: DataUpdater!
    
    func setInfo(attribute:String, data:Int) {
        stepper.value = Double(data)
        attributeLabel.text = attribute
        dataPointLabel.text = "\(data)"
    }
    
    @IBAction func updateValue(_ sender: Any) {
        dataPointLabel.text = "\(Int(stepper.value))"
        owner.updateAttribute(key: attributeLabel.text!, value: Int(stepper.value))
    }
}

class EditTableViewCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var dataTextField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    
    var lowerBound:Double = 0
    var upperBound:Double = 100000
    
    var owner: DataUpdater!
    var indexPath:IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        dataTextField.delegate = self
        
        let doneToolbar: UIToolbar = UIToolbar()
        doneToolbar.barStyle = .default
        doneToolbar.barTintColor = Colors.green
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(image: Icon.check, style: .plain, target: self, action: #selector(save))
        done.tintColor = UIColor.white
        
        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()
        
        self.dataTextField.inputAccessoryView = doneToolbar
    }
    
    @objc func save() {
        if let text = self.dataTextField.text {
            if text == "" {
                self.dataTextField.text = "\(stepper.value)"
                return
            }
            
            guard let newVal = Double(text) else {
                self.dataTextField.text = "\(stepper.value)"
                owner.updateError()
                return
            }

            if newVal < lowerBound || newVal > upperBound {
                self.dataTextField.text = "\(stepper.value)"
                owner.updateError()
                return
            }
            
            stepper.value = Double(text)!
            owner.updateData(month: attributeLabel.text!, point: Double(text)!, path: indexPath)
        }
        
        self.dataTextField.resignFirstResponder()
    }
    
    func setInfo(attribute:String, data:Double, lowerBound lb:Double?, upperBound ub:Double?) {
        stepper.value = data
        attributeLabel.text = attribute
        dataTextField.text = "\(data)"
        
        if let bound = lb {
            lowerBound = bound
            stepper.minimumValue = lowerBound
        }
        
        if let bound = ub {
            upperBound = bound
            stepper.maximumValue = upperBound
        }
    }
    
    @IBAction func updateValue(_ sender: Any) {
        dataTextField.text = "\(stepper.value)"
        owner.updateData(month: attributeLabel.text!, point: stepper.value, path: indexPath)
    }
}
