//
//  AddDataBLTNItem.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/28/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import BLTNBoard
import Material

protocol BLTNPageItemDelegate {
    func onBLTNPageItemActionClicked(with data: GreenData)
}

class AddDataBLTNItem: BLTNPageItem {
    @objc public var dateField: ErrorTextField!
    @objc public var amountField: ErrorTextField!
    @objc public var datePicker: UIDatePicker!
    public var delegate: BLTNPageItemDelegate?
    
    private var pointToolbarField: UITextField!
    private var data: GreenData
    
    init(title: String, data: GreenData) {
        self.data = data
        
        super.init(title: title.uppercased())
        
        isDismissable = true
        actionButtonTitle = "Create"
        
        appearance.titleFontDescriptor = UIFont.header.fontDescriptor
        appearance.titleTextColor = UIColor.black
        appearance.actionButtonColor = Colors.green
    }
    
    override func actionButtonTapped(sender: UIButton) {
        if dateField.text == "" || amountField.text == "" {
            return
        }
        
        let date = Date.monthFormat(string: dateField.text!)
        
        if let _ = data.findPointForDate(date, ofType: .regular) {
            dateField.isErrorRevealed = true
            amountField.resignFirstResponder()
            return
        }
        
        guard let point = Double(amountField.text!) else {
            amountField.isErrorRevealed = true
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
        
        dateField.resignFirstResponder()
        amountField.resignFirstResponder()
        
        self.delegate?.onBLTNPageItemActionClicked(with: self.data)
        
        GreenfootModal.sharedInstance.queueReminder(dataType: GreenDataType(rawValue: data.dataName)!)
    }
    
    override func makeViewsUnderTitle(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        
        setupDateField()
        setupAmountField()
        setupDatePicker()
        
        let stackView = interfaceBuilder.makeGroupStack(spacing: 20)
        stackView.addArrangedSubview(dateField)
        stackView.addArrangedSubview(amountField)
        
        let wrapper = interfaceBuilder.wrapView(stackView, width: nil, height: nil, position: .pinnedToEdges)
        
        return [wrapper]
    }
    
    private func setupAmountField() {
        amountField = ErrorTextField()
        amountField.dividerActiveColor = Colors.green
        amountField.dividerNormalColor = Colors.green
        amountField.placeholderActiveColor = Colors.green
        
        amountField.tintColor = Colors.green
        amountField.keyboardType = .decimalPad
        
        amountField.delegate = self
        amountField.addTarget(self, action: #selector(textFieldDidChange(textfield:)), for: .editingChanged)
        
        amountField.placeholder = "Amount"
        amountField.error = "Please enter a number"
        
        let doneToolbar = InputToolbar(left: nil, right: Icon.cm.check, color: Colors.green)
        doneToolbar.inputDelegate = self
        pointToolbarField = doneToolbar.centerField
        doneToolbar.color = Colors.green
        doneToolbar.itemTint = UIColor.white
        
        amountField.inputAccessoryView = doneToolbar
    }
    
    private func setupDateField() {
        dateField = ErrorTextField()
        dateField.dividerActiveColor = Colors.green
        dateField.dividerNormalColor = Colors.green
        dateField.placeholderActiveColor = Colors.green
        dateField.tintColor = Colors.green
        
        dateField.placeholder = "Date"
        dateField.error = "Duplicate Date"
    }
    
    private func setupDatePicker() {
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(monthChosen), for: .valueChanged)
        datePicker.maximumDate = Date()
        dateField.inputView = datePicker
    }
    
    @objc func resignFirstResponder(){
        amountField.resignFirstResponder()
        dateField.resignFirstResponder()
    }
    
    @objc func monthChosen() {
        let date = datePicker.date
        
        dateField.text! = Date.monthFormat(date: date)
        
        if let _ = data.findPointForDate(date, ofType: .regular) {
            dateField.isErrorRevealed = true
        } else {
            dateField.isErrorRevealed = false
        }
    }
    
    override func tearDown() {
        super.tearDown()
        self.amountField.delegate = nil
        self.delegate = nil
    }
}

extension AddDataBLTNItem: UITextFieldDelegate {
    @objc func textFieldDidChange(textfield: UITextField) {
        if textfield == amountField {
            pointToolbarField.text = amountField.text
            
            if let _ = Double(amountField.text!) {
                amountField.isErrorRevealed = false
            } else {
                amountField.isErrorRevealed = true
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddDataBLTNItem: InputToolbarDelegate {
    func leftTrigger() {
        fatalError("AddDataBLTNItem InputToolbars do not support left clicks")
    }
    
    func rightTrigger() {
        self.resignFirstResponder()
    }
}
