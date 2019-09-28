//
//  AddSourceBLTNItem.swift
//  Greenfoot
//
//  Created by Anmol Parande on 9/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation

import Foundation
import BLTNBoard
import Material

class AddSourceBLTNItem: BLTNPageItem {
    typealias SourceCategory = CarbonSource.SourceCategory
    typealias SourceType = CarbonSource.SourceType
    
    @objc public var nameField: ErrorTextField!
    @objc public var conversionField: ErrorTextField!
    @objc public var typeControlField: UISegmentedControl!
    
    public var delegate: BLTNPageItemDelegate?
    
    private var conversionToolbarField: UITextField!
    private var sourceCategory: SourceCategory
    private var sourceType: SourceType
    
    init(title: String, withSourceCategory category: SourceCategory) {
        self.sourceCategory = category
        self.sourceType = category.types[0]
        super.init(title: title.uppercased())
        
        isDismissable = true
        actionButtonTitle = "Create"
        
        appearance.titleFontDescriptor = UIFont.header.fontDescriptor
        appearance.titleTextColor = UIColor.black
        appearance.actionButtonColor = Colors.green
    }
    
    override func actionButtonTapped(sender: UIButton) {
        if nameField.text == "" || conversionField.text == "" {
            return
        }
        
        guard let conversion = Double(conversionField.text!) else {
            conversionField.isErrorRevealed = true
            return
        }
        
        nameField.resignFirstResponder()
        conversionField.resignFirstResponder()
        
        let unit = DBManager.shared.createUnit(named: "Miles", conversionToCO2: conversion, forSourceType: sourceType)
        let source = DBManager.shared.createCarbonSource(name: nameField.text!, category: sourceCategory, type: sourceType, unit: unit)
        
        self.delegate?.onBLTNPageItemActionClicked(with: source)
    }
    
    override func makeViewsUnderTitle(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        setupSegmentedControl()
        setupNameField()
        setupConversionField()

        let stackView = interfaceBuilder.makeGroupStack(spacing: 20)
        
        stackView.addArrangedSubview(typeControlField)
        stackView.addArrangedSubview(nameField)
        stackView.addArrangedSubview(conversionField)
        
        let wrapper = interfaceBuilder.wrapView(stackView, width: nil, height: nil, position: .pinnedToEdges)
        
        return [wrapper]
    }
    
    private func setupConversionField() {
        conversionField = ErrorTextField()
        conversionField.dividerActiveColor = Colors.green
        conversionField.dividerNormalColor = Colors.green
        conversionField.placeholderActiveColor = Colors.green
        
        conversionField.tintColor = Colors.green
        conversionField.keyboardType = .decimalPad
        
        conversionField.delegate = self
        conversionField.addTarget(self, action: #selector(textFieldDidChange(textfield:)), for: .editingChanged)
        
        conversionField.placeholder = "Amount"
        conversionField.error = "Please enter a number"
        
        let doneToolbar = InputToolbar(left: nil, right: Icon.cm.check, color: Colors.green)
        doneToolbar.inputDelegate = self
        conversionToolbarField = doneToolbar.centerField
        doneToolbar.color = Colors.green
        doneToolbar.itemTint = UIColor.white
        
        conversionField.inputAccessoryView = doneToolbar
    }
    
    private func setupNameField() {
        nameField = ErrorTextField()
        nameField.dividerActiveColor = Colors.green
        nameField.dividerNormalColor = Colors.green
        nameField.placeholderActiveColor = Colors.green
        nameField.tintColor = Colors.green
        
        nameField.placeholder = "Name"
        nameField.error = "Source names must be at least one character"
    }
    
    private func setupSegmentedControl() {
        let types:[String] = self.sourceCategory.types.map {$0.humanName}
        typeControlField = UISegmentedControl(items: types)
        typeControlField.tintColor = Colors.green
        typeControlField.selectedSegmentIndex = 0
        
        if types.count == 1 {
            typeControlField.isUserInteractionEnabled = false
        }
    }
    
    @objc func resignFirstResponder() {
        nameField.resignFirstResponder()
        conversionField.resignFirstResponder()
    }
    
    override func tearDown() {
        super.tearDown()
        self.conversionField.delegate = nil
        self.nameField.delegate = nil
        self.delegate = nil
    }
}

extension AddSourceBLTNItem: UITextFieldDelegate {
    @objc func textFieldDidChange(textfield: UITextField) {
        if textfield == conversionField {
            conversionToolbarField.text = conversionField.text
            
            if let _ = Double(conversionField.text!) {
                conversionField.isErrorRevealed = false
            } else {
                conversionField.isErrorRevealed = true
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension AddSourceBLTNItem: InputToolbarDelegate {
    func leftTrigger() {
        #warning("Error not handled gracefully")
        fatalError("AddDataBLTNItem InputToolbars do not support left clicks")
    }
    
    func rightTrigger() {
        self.resignFirstResponder()
    }
}
