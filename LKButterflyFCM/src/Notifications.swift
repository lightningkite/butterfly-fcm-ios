//
//  Notifications.swift
//  LKButterflyFCM
//
//  Created by Joseph Ivie on 1/21/20.
//  Copyright © 2020 Lightning Kite. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import LKButterfly


public class Notifications {
    static public var useCritical = false
    static public let INSTANCE = Notifications()

    public var notificationToken = StandardObservableProperty<String?>(underlyingValue: nil)
    public func hasPermission(onResult: @escaping (Bool)->Void) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            onResult(it.authorizationStatus.rawValue >= UNAuthorizationStatus.authorized.rawValue)
        }
    }
    public func request(insistMessage: ViewString? = nil, onResult: @escaping (Bool)->Void = { _ in }) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            if it.authorizationStatus.rawValue >= UNAuthorizationStatus.authorized.rawValue {
                onResult(true)
                return
            } else if it.authorizationStatus == .notDetermined {
                var options: UNAuthorizationOptions = [.alert, .sound, .badge]
                if #available(iOS 12.0, *) {
                    if Notifications.useCritical {
                        options = [.alert, .sound, .badge, .criticalAlert]
                    }
                }
                UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (success, error) in
                    if success {
                        Notifications.INSTANCE.notificationToken.value = Messaging.messaging().fcmToken
                    }
                    onResult(success)
                })
            } else if let insistMessage = insistMessage {
                DispatchQueue.main.async {
                    showDialog(request: DialogRequest(
                        string: insistMessage,
                        confirmation: { () in
                            DispatchQueue.main.async {
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    if #available(iOS 10.0, *) {
                                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                            print("Settings opened: \(success)") // Prints true
                                        })
                                    } else {
                                        UIApplication.shared.openURL(settingsUrl as URL)
                                    }
                                }
                            }
                        }
                    ))
                }
            }
        }
    }
    public func configure(){
        request()
    }
}
