//
//  SummaryContainerViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/29/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UIKit

class SummaryContainerViewController: UIViewController {
    @IBOutlet weak var tableContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableContainerView.backgroundColor = UIColor.clear
        tableContainerView.layer.shadowColor = UIColor.darkGray.cgColor
        tableContainerView.layer.shadowOffset = CGSize(width: 0, height: -1.0)
        tableContainerView.layer.shadowOpacity = 1.0
        tableContainerView.layer.shadowRadius = 10
    }
}
