//
//  ViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 12/25/16.
//  Copyright © 2016 Anmol Parande. All rights reserved.
//

import UIKit
import Material

class SummaryViewController: UIViewController {
    
    @IBOutlet weak var pointLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let menuButton = IconButton(image: Icon.cm.menu)
        menuButton.addTarget(navigationDrawerController, action: #selector(NavigationDrawerController.openLeftView(velocity:)), for: .touchUpInside)
        navigationItem.leftViews = [menuButton]
        
        let logo = UIImageView(image: UIImage(named: "plant"))
        navigationItem.centerViews = [logo]
        logo.contentMode = .scaleAspectFit
        
        menuButton.tintColor = UIColor.white
        navigationController?.navigationBar.barTintColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1.0)
    }
}

