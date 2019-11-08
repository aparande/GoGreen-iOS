//
//  NotificationManager.swift
//  Greenfoot
//
//  Created by Anmol Parande on 10/27/19.
//  Copyright © 2019 Anmol Parande. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager {
    private var canNotify: Bool
    private var reminderSettings: [String:ReminderSetting]
    private var scheduledReminders:[String:String]
    
    static var shared = NotificationManager()
    
    private init() {
        let defaults = UserDefaults.standard
        self.canNotify = defaults.bool(forKey: DefaultsKeys.CAN_NOTIFY)
        
        self.reminderSettings = [:]
        self.scheduledReminders = [:]
    }
    
    func reminderSetting(forSource source: CarbonSource) -> ReminderSetting {
        guard let id = source.id else { return .None }
        return self.reminderSettings[id] ?? .None
    }
    
    private func setNotificationCategories() {
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                 actions: [],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
        UNUserNotificationCenter.current().setNotificationCategories([generalCategory])
    }
    
    func scheduleNotification(forSource source: CarbonSource,  withSetting setting: ReminderSetting = .FirstOfMonth) {
        guard let id = source.id else { return }
        
        if !canNotify {
            reminderSettings[id] = .None
            return
        }
        
        reminderSettings[id] = setting
        
        
        let components: DateComponents
        switch setting {
        case .FirstOfMonth:
            components = DateComponents(calendar: Calendar.current, day: 1)
            break
        case .OneMonth:
            let today = Date()
            components = Calendar.current.dateComponents([.day], from: today)
        default:
            self.cancelNotification(forSource: source)
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        
        content.title = "Log Data For \(source.name)"
        content.body = "It's time to log your \(source.sourceType.humanName) usage"
        
        let identifier = "\(id)-monthly-notification"
        self.scheduledReminders[id] = identifier
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (err) in
            if err != nil {
                print("error: \(String(describing: err))")
            }
        }
    }
    
    func requestNotificationPermissions(completion: ((Bool) -> Void)?) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if error != nil {
                print(error.debugDescription)
            }
            
            self.canNotify = granted
            
            if granted {
                for source in CarbonSource.all(inContext: DBManager.shared.backgroundContext) {
                    guard let id = source.id else { continue }
                    self.reminderSettings[id] = .FirstOfMonth
                }
            }
            
            completion?(granted)
        }
    }
    
    func cancelNotification(forSource source: CarbonSource) {
        if let sourceId = source.id, let id = scheduledReminders[sourceId] {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
            scheduledReminders.removeValue(forKey: id)
        }
    }
    
    func cancelAllNotifications() {
        var scheduled:[String] = []
        for (_, notifId) in self.scheduledReminders {
            scheduled.append(notifId)
        }
        self.scheduledReminders = [:]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: scheduled)
    }
}

enum ReminderSetting: String {
    case FirstOfMonth = "First of Each Month", OneMonth = "One Month from Last Point", None = "Never"
    
    static var all:[ReminderSetting] {
        return [.FirstOfMonth, .OneMonth, .None]
    }
}
