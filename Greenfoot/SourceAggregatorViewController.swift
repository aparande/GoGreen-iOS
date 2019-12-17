//
//  SourceAggregatorViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 8/4/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import UIKit
import BLTNBoard

class SourceAggregatorViewController: UIViewController, BLTNPageItemDelegate {
    var aggregator: SourceAggregator!
    var errorInfo: [String: String]?
    private var shouldErrorOnPresent = false
    
    private let ERROR_TITLE_KEY = "title"
    private let ERROR_MESSAGE_KEY = "message"
    private let ERROR_OK_BUTTON_TITLE = "Ok"
    
    var bulletinManager: BLTNItemManager?
    
    func presentBulletin(forSource source: CarbonSource) {
        let rootItem: AddDataBLTNItem = AddDataBLTNItem(title: "Add Data", source: source)
        rootItem.delegate = self
        bulletinManager = BLTNItemManager(rootItem: rootItem)
        bulletinManager?.showBulletin(above: self)
    }
    
    func onBLTNPageItemActionClicked(with source: CarbonSource) {
        aggregator.refresh()
        bulletinManager?.dismissBulletin(animated: true)
        bulletinManager = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldErrorOnPresent, let info = errorInfo {
            let alertView = UIAlertController(title: info[ERROR_TITLE_KEY]!, message: info[ERROR_MESSAGE_KEY]!, preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: ERROR_OK_BUTTON_TITLE, style: .cancel, handler: nil))
            self.present(alertView, animated: true, completion: {
                self.shouldErrorOnPresent = false
            })
        }
        
        refresh()
    }
    
    func errorOnPresent(titled title:String, withMessage message: String) {
        var info: [String:String] = [:]
        info[ERROR_TITLE_KEY] = title
        info[ERROR_MESSAGE_KEY] = message
        self.errorInfo = info
        
        self.shouldErrorOnPresent = true
    }
    
    func refresh() {
        aggregator.refresh()
    }
}