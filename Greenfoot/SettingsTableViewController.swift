//
//  SettingsTableViewController.swift
//  Greenfoot
//
//  Created by Anmol Parande on 1/2/18.
//  Copyright © 2018 Anmol Parande. All rights reserved.
//

import UIKit
import Material
import PopupDialog

class SettingsTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var locationSwitch: Switch!
    var notificationSwitch: Switch!
    
    var shouldUpdateNotifications: Bool
    var shouldUpdateLocation: Bool
    
    init() {
        shouldUpdateNotifications = false
        shouldUpdateLocation = false
        super.init(style: .grouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepNavigationBar(titled: "Settings")
        
        //Table View Customization
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var setting:Settings?
        switch indexPath.section {
        case 0:
            setting = .LocationAllowed
        case 1:
            setting = .NotificationAllowed
        default:
            break
        }
        
        if let theSetting = setting {
            if indexPath.row == 0 {
                return switchCellForSetting(theSetting)
            }
            
            if theSetting == .NotificationAllowed {
                return notificationCellForPath(indexPath)
            }
            
            return standardCellForPath(indexPath)
        } else {
            return standardCellForPath(indexPath)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return (SettingsManager.sharedInstance.canNotify) ? 5 : 1
        case 2:
            return 4
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch  section {
        case 0:
            return "Location"
        case 1:
            return "Reminders"
        case 2:
            return "Information"
        default:
            return "Information"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row != 0 {
            tableView.cellForRow(at: indexPath)?.accessoryView?.becomeFirstResponder()
        }
        
        if indexPath.section != 2 {
            return
        }
        
        switch indexPath.row {
        case 0:
            let cvc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AboutViewController")
            self.navigationController?.pushViewController(cvc, animated: true)
        case 1:
            let contentHeight:CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 1000 : 2000
            let vc = FileScrollViewController(fileName: "license", contentHeight: contentHeight)
            self.navigationController?.pushViewController(vc, animated: true)
        case 2:
            let contentHeight:CGFloat = (UIDevice.current.userInterfaceIdiom == .pad) ? 2500 : 4000
            let vc = FileScrollViewController(fileName: "privacy", contentHeight: contentHeight)
            self.navigationController?.pushViewController(vc, animated: true)
        case 3:
            if (!(SettingsManager.sharedInstance.profile["linked"] as! Bool)) {
                showLogin()
            }
            tableView.deselectRow(at: indexPath, animated: false)
        default:
            return
        }
    }
    
    private func showLogin() {
        // Present Login
        self.present(PopupDialog.getPopupDialog(for: "Login", controlledBy: self), animated: true, completion: nil)
    }
    
    private func standardCellForPath(_ indexPath:IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "General")
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "FAQ"
        case 1:
            cell.textLabel?.text = "See License"
        case 2:
            cell.textLabel?.text = "Privacy Policy"
        case 3:
            if (!(SettingsManager.sharedInstance.profile["linked"] as! Bool)) {
                cell.textLabel?.text = "Link Device"
            } else {
                cell.textLabel?.text = "Device Linked"
            }
            
        default:
            cell.textLabel?.text = ""
        }
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    private func notificationCellForPath(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "NotificationCell")
        
        let dataType = GreenDataType.allValues[indexPath.row-1]
        
        let title = dataType.rawValue
        let value = SettingsManager.sharedInstance.reminderTimings?[dataType]?.rawValue
        
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = "\(value!)"
        
        let textField = UITextField(frame: CGRect.zero)
        
        let picker = TableViewCellPicker()
        picker.tableViewCell = cell
        picker.delegate = self
        picker.dataSource = self
        picker.textField = textField
        picker.indexPath = indexPath
        
        textField.inputView = picker
        cell.accessoryView = textField
        
        return cell
    }
    
    private func switchCellForSetting(_ setting: Settings) -> UITableViewCell {
        //let cell = UITableViewCell(style: .default, reuseIdentifier: "Switch")
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Switch")
        
        let switchView = Switch(state: .off, style: .dark, size: .small)
        switchView.addTarget(self, action: #selector(updateSetting(_:)), for: .valueChanged)
        switchView.buttonOnColor = Colors.green
        
        switch (setting) {
        case .LocationAllowed:
            cell.textLabel?.text = "Location"
            locationSwitch = switchView
            switchView.setSwitchState(state: (SettingsManager.sharedInstance.shouldUseLocation) ? .on : .off)
        case .NotificationAllowed:
            cell.textLabel?.text = "Reminders"
            notificationSwitch = switchView
            switchView.setSwitchState(state: (SettingsManager.sharedInstance.canNotify) ? .on : .off)
        }
        
        cell.accessoryView = switchView
        
        return cell
    }
    
    @objc func updateSetting(_ sender: Switch) {
        if sender.isEqual(locationSwitch) {
            updateLocationSetting(newValue: (sender.switchState == .on))
        } else {
            updateNotificationSetting(newValue: (sender.switchState == .on))
        }
    }
    
    private func updateNotificationSetting(newValue: Bool) {
        SettingsManager.sharedInstance.canNotify = newValue
        if newValue {
            SettingsManager.sharedInstance.requestNotificationPermissions(completion: {
                (granted) in
                if !granted {
                    DispatchQueue.main.async {
                        SettingsManager.sharedInstance.canNotify = false
                        self.notificationSwitch.setSwitchState(state: .off)
                    }
                    
                    let alertView = UIAlertController(title: "Notification Permission", message: "In order to turn on reminds, you need to enable permissions in the Settings Application.", preferredStyle: .alert)
                    alertView.addAction(UIAlertAction(title: "Open", style: .default, handler: {
                        _ in
                        
                        DispatchQueue.main.async {
                            self.shouldUpdateNotifications = true
                            
                            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                                return
                            }
                            
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.open(settingsUrl, completionHandler: {
                                    _ in
                                    
                                    NotificationCenter.default.addObserver(self, selector: #selector(self.checkNotificationUpdate), name: .UIApplicationDidBecomeActive, object: nil)
                                })
                            }
                        }
                    }))
                    alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(alertView, animated: true, completion: nil)
                } else {
                    DispatchQueue.main.async {
                        self.tableView.beginUpdates()
                        self.tableView.reloadSections([1], with: UITableViewRowAnimation.automatic)
                        self.tableView.endUpdates()
                    }
                }
            })
        } else {
            self.tableView.beginUpdates()
            self.tableView.reloadSections([1], with: .automatic)
            self.tableView.endUpdates()
            
            SettingsManager.sharedInstance.cancelAllNotifications()
        }
    }
    
    private func updateLocationSetting(newValue: Bool) {
        SettingsManager.sharedInstance.shouldUseLocation = newValue
        if newValue {
            guard let savedLocale = SettingsManager.sharedInstance.locality else {
                NotificationCenter.default.addObserver(self, selector: #selector(requestLocationPermissions), name: SettingsManager.sharedInstance.locationFailedNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: SettingsManager.sharedInstance.locationUpdatedNotification, object: nil)
                
                SettingsManager.sharedInstance.loadLocation()
                return
            }
            
            GreenfootModal.sharedInstance.locality = savedLocale
        } else {
            //This becomes null, but the locale is still stored in SettingsManager
            GreenfootModal.sharedInstance.locality = nil
        }
    }
    
    @objc func requestLocationPermissions() {
        NotificationCenter.default.removeObserver(self, name: SettingsManager.sharedInstance.locationFailedNotification, object: nil)
        
        DispatchQueue.main.async {
            self.locationSwitch.setSwitchState(state: .off)
            let alertView = UIAlertController(title: "Location Permission", message: "Your location is used to compare you with others in your city and your state. To turn on location, you must enable it in the Settings Application", preferredStyle: .alert)
            alertView.addAction(UIAlertAction(title: "Open", style: .default, handler: {
                _ in
                
                DispatchQueue.main.async {
                    self.shouldUpdateLocation = true
                    
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: {
                            _ in
                            
                            NotificationCenter.default.addObserver(self, selector: #selector(self.checkLocationUpdate), name: .UIApplicationDidBecomeActive, object: nil)
                        })
                    }
                }
            }))
            alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {
                _ in
                SettingsManager.sharedInstance.shouldUseLocation = false
                DispatchQueue.main.async {
                    self.locationSwitch.setSwitchState(state: .off)
                }
            }))
            self.present(alertView, animated: true, completion: nil)
        }
    }
    
    @objc func checkNotificationUpdate() {
        if !shouldUpdateNotifications {
            return
        }
        
        SettingsManager.sharedInstance.requestNotificationPermissions(completion: {
            granted in
            SettingsManager.sharedInstance.canNotify = granted
            DispatchQueue.main.async {
                self.notificationSwitch.setSwitchState(state: (granted) ? .on : .off, animated: true, completion: nil)
                
                if granted {
                    self.tableView.beginUpdates()
                    self.tableView.reloadSections([1], with: .automatic)
                    self.tableView.endUpdates()
                }
            }
            self.shouldUpdateNotifications = false
        })
    }
    
    @objc func checkLocationUpdate() {
        NotificationCenter.default.removeObserver(self, name: SettingsManager.sharedInstance.locationUpdatedNotification, object: nil)
        if !shouldUpdateLocation {
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(requestLocationPermissions), name: SettingsManager.sharedInstance.locationFailedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: SettingsManager.sharedInstance.locationUpdatedNotification, object: nil)
        SettingsManager.sharedInstance.loadLocation()
    }
    
    @objc func locationUpdated () {
        self.locationSwitch.setSwitchState(state: .on)
        print("Location Updated in Settings")
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return ReminderSettings.allValues[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let tablePicker = pickerView as? TableViewCellPicker else {
            print("This is not a Table View Cell Picker")
            return
        }
        
        guard let cell = tablePicker.tableViewCell else {
            print("Forgot to assign table view cell to picker")
            return
        }
        
        guard let field = tablePicker.textField else {
            print("Forgot to assign text field to picker")
            return
        }
        
        guard let indexPath = tablePicker.indexPath else {
            print("Forgot to assign index path to picker")
            return
        }
        
        let dataType = GreenDataType.allValues[indexPath.row-1]
        SettingsManager.sharedInstance.reminderTimings![dataType] = ReminderSettings.allValues[row]
        
        cell.detailTextLabel?.text = ReminderSettings.allValues[row].rawValue
        
        if ReminderSettings.allValues[row] == .None {
            SettingsManager.sharedInstance.cancelNotificationforDataType(dataType)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        field.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var userField: TextField!
    @IBOutlet var passField: TextField!
    @IBOutlet var messageLabel: UILabel!
    
    override func viewDidLoad() {
        userField.leftView = UIImageView(image: Icon.email?.withRenderingMode(.alwaysTemplate))
        let lockView = UIImageView(image: Icon.lock.resize(toWidth: Icon.email!.width)?.withRenderingMode(.alwaysTemplate))
        passField.leftView = lockView
        
        userField.dividerActiveColor = Colors.green
        passField.dividerActiveColor = Colors.green
        
        userField.leftViewActiveColor = Colors.green
        passField.leftViewActiveColor = Colors.green
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class SignupViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var userField: TextField!
    @IBOutlet var passField: TextField!
    @IBOutlet var repassField: TextField!
    @IBOutlet var firstNameField: TextField!
    @IBOutlet var lastNameField: TextField!
    @IBOutlet var messageLabel: UILabel!
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let emailWidth = Icon.email!.width
        let lockImage = Icon.lock.resize(toWidth: emailWidth)?.withRenderingMode(.alwaysTemplate)
        let nameImage = Icon.person.resize(toWidth: emailWidth)?.withRenderingMode(.alwaysTemplate)
            
        userField.leftView = UIImageView(image: Icon.email?.withRenderingMode(.alwaysTemplate))
        
        passField.leftView = UIImageView(image: lockImage)
        repassField.leftView = UIImageView(image: lockImage)
       
        firstNameField.leftView = UIImageView(image: nameImage)
        lastNameField.leftView = UIImageView(image: nameImage)
        
        userField.dividerActiveColor = Colors.green
        passField.dividerActiveColor = Colors.green
        repassField.dividerActiveColor = Colors.green
        firstNameField.dividerActiveColor = Colors.green
        lastNameField.dividerActiveColor = Colors.green
        
        userField.leftViewActiveColor = Colors.green
        passField.leftViewActiveColor = Colors.green
        repassField.leftViewActiveColor = Colors.green
        firstNameField.leftViewActiveColor = Colors.green
        lastNameField.leftViewActiveColor = Colors.green
    }
}

class TableViewCellPicker: UIPickerView {
    var tableViewCell: UITableViewCell?
    var textField: UITextField?
    var indexPath: IndexPath?
}

extension PopupDialog {
    static func getPopupDialog(for type: String, controlledBy viewController: UIViewController) -> PopupDialog {
        let cancelButton = CancelButton(title: "CANCEL", action: nil)
        if type == "Login" {
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
                                if let tutorialViewController = viewController as? TutorialPageViewController {
                                    tutorialViewController.delegate.tutorialComplete()
                                }
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
            
            //Add the buttons
            loginPopup.addButtons([loginButton, createButton, cancelButton])
            return loginPopup
        } else {
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
                                if let tutorialViewController = viewController as? TutorialPageViewController {
                                    tutorialViewController.delegate.signedIn()
                                }
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
            return signupPopup
        }
    }
}
