//
//  PopupDialog.swift
//  Greenfoot
//
//  Created by Anmol Parande on 6/16/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import PopupDialog

extension PopupDialog {
    static func getPopupDialog(for type: String, controlledBy viewController: UIViewController) -> PopupDialog {
        return PopupDialog(title: "Bllop", message: "Broken ATM")
        let cancelButton = CancelButton(title: "CANCEL", action: nil)
        if type == "Login" {
            /*
            // Create the login dialog
            let lvc = UIStoryboard(name: "Account", bundle: nil).instantiateInitialViewController()! as! LoginViewController
            let loginPopup = PopupDialog(viewController: lvc)
            
            //Create some buttons
            let loginButton = DefaultButton(title: "Login", dismissOnTap: false) {
                SettingsManager.sharedInstance.login(email: lvc.userField.text!, password: lvc.passField.text!, completion: {
                    (success, err) in
                    DispatchQueue.main.async {
                        if success {
                            if let tableViewController = viewController as? UITableViewController {
                                tableViewController.tableView.reloadSections([2], with: .none)
                            }
                            loginPopup.dismiss() {
                                /*
                                if let tutorialViewController = viewController as? TutorialPageViewController {
                                    tutorialViewController.delegate.tutorialComplete()
                                    return
                                }
                                
                                if let _ = viewController as? SettingsTableViewController {
                                    let popupDialog = PopupDialog(title: "Logged In!", message: "You have successfully logged in! You should now be able to see all data from your other devices.")
                                    let continueButton = PopupDialogButton(title: "Ok", dismissOnTap: true, action: nil)
                                    popupDialog.addButton(continueButton)
                                    viewController.present(popupDialog, animated: true, completion: nil)
                                }
                                */
                            }
                        } else {
                            if let _ = err {
                                lvc.messageLabel.text = err!
                            }
                            loginPopup.shake()
                        }
                    }
                })
            }
            
            let createButton = DefaultButton(title: "Create Account", dismissOnTap: false) {
                loginPopup.dismiss() {
                    let signupPopup = PopupDialog.getPopupDialog(for: "Signup", controlledBy: viewController)
                    viewController.present(signupPopup, animated: true, completion: nil)
                }
            }
            
            let resetButton = DefaultButton(title: "Forgot Password", dismissOnTap: false) {
                //let resetUrl = URL(string: "http://192.168.1.94:8000/reset")!
                let resetUrl = URL(string: "https://gogreencarbonapp.herokuapp.com/reset")!
                UIApplication.shared.open(resetUrl, options: [:], completionHandler: nil)
            }
            
            //Add the buttons
            loginPopup.addButtons([loginButton, createButton, resetButton, cancelButton])
            return loginPopup */
        } else {
            /*
            //Create the signup dialog
            let svc = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "Signup") as! SignupViewController
            let signupPopup = PopupDialog(viewController: svc)
            
            let backButton = DefaultButton(title: "Back", dismissOnTap: false) {
                signupPopup.dismiss({
                    let loginPopup = self.getPopupDialog(for: "Login", controlledBy: viewController)
                    viewController.present(loginPopup, animated: true, completion: nil)
                })
            }
            
            let signupButton = DefaultButton(title: "Signup", dismissOnTap: false) {
                
                SettingsManager.sharedInstance.signup(email: svc.userField.text!, password: svc.passField.text!, retypedPassword: svc.repassField.text!, firstname: svc.firstNameField.text!, lastname: svc.lastNameField.text!, completion: {
                    (success, err) in
                    DispatchQueue.main.async {
                        if success {
                            if let tableViewController = viewController as? UITableViewController {
                                tableViewController.tableView.reloadSections([2], with: .none)
                            }
                            
                            signupPopup.dismiss() {
                                /*
                                if let tutorialViewController = viewController as? TutorialPageViewController {
                                    tutorialViewController.delegate.signedIn()
                                }
                                
                                if let _ = viewController as? SettingsTableViewController {
                                    let popupDialog = PopupDialog(title: "Sign up successful", message: "Thank you for making an account! Use the same email address and password to access your data on your other devices.")
                                    let continueButton = PopupDialogButton(title: "Ok", dismissOnTap: true, action: nil)
                                    popupDialog.addButton(continueButton)
                                    viewController.present(popupDialog, animated: true, completion: nil)
                                } */
                            }
                        } else {
                            if let _ = err {
                                svc.messageLabel.text = err!
                            }
                            signupPopup.shake()
                        }
                    }
                })
            }
            
            signupPopup.addButtons([signupButton, backButton, cancelButton])
            return signupPopup */
        }
    }
}
