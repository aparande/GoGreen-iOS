//
//  TutorialPageViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 5/11/17.
//  Copyright © 2017 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import PopupDialog

protocol TutorialPageDelegate {
    func skipPage()
    func tutorialComplete()
    func signedIn()
}

class TutorialPageViewController: UIViewController, UITextFieldDelegate  {

    var delegate:TutorialPageDelegate!
    var hasAttributes:Bool!
    var isFinal: Bool!
    var isLogin: Bool = false
    
    //Normal View Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var slideTitleLabel: UILabel!
    @IBOutlet weak var slideDescriptionLabel: UILabel!
    @IBOutlet weak var goButton: RaisedButton!
    @IBOutlet weak var skipButton: UIButton!
    
    //Normal View Variables
    var dataType:GreenDataType?
    var icon:UIImage!
    var slideDescription: String!
    var units:String?
    var pageTitle:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        iconImageView.image  = icon
        slideTitleLabel.text = pageTitle
        slideDescriptionLabel.text = slideDescription
        
        slideTitleLabel.sizeToFit()
        slideDescriptionLabel.sizeToFit()
        
        if !hasAttributes {
            skipButton.isHidden = true
            goButton.removeTarget(self, action: #selector(revealDataAdder), for: .touchUpInside)
            goButton.addTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
            goButton.setTitle("Next", for: .normal)
        }
        
        if isLogin {
            skipButton.isHidden = false
            goButton.removeTarget(self, action: #selector(skip(_:)), for: .touchUpInside)
            goButton.addTarget(self, action: #selector(showLogin), for: .touchUpInside)
            goButton.setTitle("Sign In", for: .normal)
            skipButton.setTitle("Next", for: .normal)
        }
    }
    
    @IBAction func revealDataAdder() {
        guard let type = dataType else {
            return
        }
        
        let greenData = GreenfootModal.sharedInstance.data[type]!
        
        let bulkAdder = BulkDataViewController(withData: greenData)
        let nvc = NavigationController(rootViewController: bulkAdder)
        self.present(nvc, animated: true, completion: {
            self.goButton.setTitle("Next", for: .normal)
            self.skipButton.setTitle("Edit", for: .normal)
            
            self.goButton.removeTarget(self, action: #selector(self.revealDataAdder), for: .touchUpInside)
            self.goButton.addTarget(self, action: #selector(self.skip(_:)), for: .touchUpInside)
            self.skipButton.removeTarget(self, action: #selector(self.skip(_:)), for: .touchUpInside)
            self.skipButton.addTarget(self, action: #selector(self.revealDataAdder), for: .touchUpInside)
        })
        
        return
    }
    
    @objc func showLogin() {
        self.present(PopupDialog.getPopupDialog(for: "Login", controlledBy: self), animated: true, completion: nil)
    }
    
    func setValues(title: String, description: String, icon: UIImage, units: String?, isEditable:Bool) {
        pageTitle = title
        dataType = GreenDataType(rawValue: title)
        self.units = units
        slideDescription = description
        self.icon = icon
        hasAttributes = isEditable
    }
    
    @IBAction func skip(_ sender: Any) {
        delegate.skipPage()
    }
}
