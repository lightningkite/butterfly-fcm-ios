//
//  Notifications.swift
//  ButterflyFCM
//
//  Created by Joseph Ivie on 1/21/20.
//  Copyright © 2020 Lightning Kite. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseMessaging
import Butterfly


public class Notifications {
    static public let INSTANCE = Notifications()

    public var notificationToken = StandardObservableProperty<String?>(underlyingValue: nil)
    public func hasPermission(onResult: @escaping (Bool)->Void) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            onResult(it.authorizationStatus >= .authorized)
        }
    }
    public func request(insistMessage: ViewString? = nil, onResult: @escaping (Bool)->Void = { _ in }) {
        UNUserNotificationCenter.current().getNotificationSettings { it in
            if it.authorizationStatus >= .authorized {
                onResult(true)
                return
            } else if it.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: { (success, error) in
                    if success {
                        if let firebaseAppName = firebaseAppName, let app = FirebaseApp.app(name: firebaseAppName), let current = FirebaseApp.app() {
                            current.delete { (x) in
                                FirebaseApp.configure(options: app.options)
                                Notifications.INSTANCE.notificationToken.value = Messaging.messaging().fcmToken
                            }
                        } else {
                            Notifications.INSTANCE.notificationToken.value = Messaging.messaging().fcmToken
                        }
                    }
                    onResult(success)
                })
            } else if let insistMessage = insistMessage {
                showMessage(request: DialogRequest(
                    string: insistMessage,
                    confirmation: { in
                        DispatchQueue.main.async {
                            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
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
    public func configure(){
        request()
    }
}
