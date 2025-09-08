//
//  AppDelegate.swift
//  WebViewGold
//

import UIKit
import UserNotifications
import OneSignal
import CoreLocation
import GoogleMobileAds
import Firebase
import FirebaseMessaging
import SwiftyStoreKit
import AVFoundation
import FBAudienceNetwork
import AppTrackingTransparency
import Pushwoosh
import EventKit
import SwiftUI
import LocalAuthentication

#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

// MARK: - Location Manager
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    let locationManager = CLLocationManager()

    override init() {
        super.init()
        if Constants.backgroundlocation {
            locationManager.delegate = self
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.pausesLocationUpdatesAutomatically = false
            // ⚠️ Do not request authorization here; we'll request after onboarding.
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        NotificationCenter.default.post(name: NSNotification.Name("LocationUpdate"), object: location)
    }

    // Ask When-In-Use first, then (optionally) Always. Call this after onboarding CTA.
    func requestPermissions(askAlways: Bool = Constants.backgroundlocation,
                            completion: (() -> Void)? = nil) {
        // Request foreground first so iOS presents the gentler prompt flow.
        self.locationManager.requestWhenInUseAuthorization()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if askAlways {
                self.locationManager.requestAlwaysAuthorization()
            }
            completion?()
        }
    }

    // iOS 14+: If the user has Reduced Accuracy ON, request temporary full accuracy ("Precise")
    func ensurePreciseAccuracy(purposeKey: String = "LocationPreciseUsage",
                               completion: ((Bool) -> Void)? = nil) {
        guard #available(iOS 14.0, *) else {
            completion?(true); return
        }
        if self.locationManager.accuracyAuthorization == .fullAccuracy {
            completion?(true)
            return
        }
        self.locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey) { error in
            if let error = error {
                print("Full accuracy request error:", error)
            }
            let isFull = (self.locationManager.accuracyAuthorization == .fullAccuracy)
            completion?(isFull)
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PWMessagingDelegate {

    var isActive = false
    var orientationLock = UIInterfaceOrientationMask.all
    var window: UIWindow?

    // MARK: - First-launch Onboarding
    private let kDidSeeOnboarding = "didSeeOnboarding_v1"
    private let kSkipBioOnce      = "wvg.skipBioOnce"
    private let kDidAskATTOnce    = "wvg.didAskATTOnce"

    // MARK: Orientation Lock
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let idiom = UIDevice.current.userInterfaceIdiom
        let orientation = idiom == .pad ? orientationipad : orientationiphone

        switch orientation {
        case "portrait":  orientationLock = .portrait
        case "landscape": orientationLock = .landscape    
        default:          orientationLock = .all
        }
        return self.orientationLock
    }

    struct AppUtility {
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                delegate.orientationLock = orientation
            }
        }
        static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
            self.lockOrientation(orientation)
            UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
        }
    }

    // MARK: - AppsFlyer Helpers
    private func wvg_getOrCreateDeviceCUID() -> String {
        let key = "customUserID"
        if let saved = UserDefaults.standard.string(forKey: key) {
            return saved
        }
        let newId = "guest_" + UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    private func wvg_startAppsFlyer() {
        #if canImport(AppsFlyerLib)
        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = "kBJj3TfQcrfWYpE3jiCtZD"
        af.appleAppID = "6749654460"
        af.customerUserID = wvg_getOrCreateDeviceCUID()
        af.start { (result, error) in
            if let error = error {
                print("AppsFlyer start error:", error)
            } else {
                print("AppsFlyer started:", result ?? [:])
            }
        }
        #endif
    }

    // MARK: - App Lifecycle
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        WebViewController.installBottomTabsSwizzle()
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Your normal root VC is created by Main storyboard or programmatically,
        // so the web app loads behind onboarding.
        if Constants.backgroundlocation {
            _ = LocationManager.shared
        }

        // Init SDKs that don’t prompt the user
        wvg_startAppsFlyer()
        UIApplication.shared.applicationIconBadgeNumber = 0

        if (Constants.useFacebookAds) {
            FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)
        }

        // Firebase: configure ONLY. (We will ask notification permission later)
        if Constants.kFirebasePushEnabled {
            FirebaseApp.configure()
            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self
            // DO NOT requestAuthorization or registerForRemoteNotifications here.
        }

        if (Constants.kPushEnabled) {
            OneSignal.setAppId(Constants.oneSignalID)
            OneSignal.initWithLaunchOptions(launchOptions)
            OneSignal.setLaunchURLsInApp(false)
        }

        if(Constants.kPushwooshEnable) {
            Pushwoosh.sharedInstance().delegate = self
            Pushwoosh.sharedInstance().registerForPushNotifications()
        }

        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction { SwiftyStoreKit.finishTransaction(purchase.transaction) }
                default: break
                }
            }
        }

        if UserDefaults.standard.value(forKey: "IsPurchase") == nil {
            UserDefaults.standard.setValue("NO", forKey: "IsPurchase")
        }

        // ✅ Present onboarding on first launch; ATT appears immediately, other prompts after CTA.
        showOnboardingIfNeeded()

        return true
    }

    // MARK: - Onboarding presentation (ATT at presentation time)
    private func showOnboardingIfNeeded() {
        guard let root = window?.rootViewController else { return }
        guard !UserDefaults.standard.bool(forKey: kDidSeeOnboarding) else { return }

        let hosting = UIHostingController(
            rootView: OnboardingView(onDone: { [weak self] in
                guard let self = self else { return }
                UserDefaults.standard.set(true, forKey: self.kDidSeeOnboarding)
                UserDefaults.standard.set(true, forKey: self.kSkipBioOnce)

                root.dismiss(animated: true) {
                    // After onboarding CTA:
                    // 0) Location permissions + precise accuracy (Precise Location)
                    LocationManager.shared.requestPermissions(askAlways: Constants.backgroundlocation) {
                        LocationManager.shared.ensurePreciseAccuracy(purposeKey: "LocationPreciseUsage") { _ in
                            // 1) Biometrics
                            self.requestBiometrics { _ in
                                // 2) Notifications
                                self.requestNotifications {
                                    // (ATT already shown when onboarding appeared)
                                }
                            }
                        }
                    }
                }
            })
        )
        hosting.modalPresentationStyle = .fullScreen

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            root.present(hosting, animated: true) { [weak self] in
                guard let self = self else { return }
                // Show ATT as the onboarding comes up (only once ever)
                if #available(iOS 14, *),
                   UserDefaults.standard.bool(forKey: self.kDidAskATTOnce) == false {
                    self.requestTrackingTransparency()
                }
            }
        }
    }

    // MARK: - Permission helpers (run AFTER onboarding CTA)

    /// Face ID / Touch ID
    private func requestBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: "Authenticate to continue") { success, _ in
                DispatchQueue.main.async {
                    print(success ? "✅ Biometrics OK" : "❌ Biometrics failed")
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }

    /// Notifications (requests permission, then registers with APNs so FCM can fetch token)
    private func requestNotifications(completion: @escaping () -> Void) {
        guard Constants.kFirebasePushEnabled else {
            completion()
            return
        }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
            if let err = err { print("UN permission error:", err) }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    completion()
                }
            } else {
                completion()
            }
        }
    }

    /// ATT prompt (sets a one-time flag)
    private func requestTrackingTransparency() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                guard let self = self else { return }
                UserDefaults.standard.set(true, forKey: self.kDidAskATTOnce)
                print("ATT status: \(status.rawValue)")
            }
        }
    }

    // MARK: - Extras
    func deactivatedarkmode() {
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .light
        }
    }

    // MARK: - Universal Links / URL Schemes
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        #endif
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().handleOpen(url, options: options)
        #endif
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Do NOT call ATT here; it runs when onboarding is presented.
    }
}

// MARK: - Firebase / Push delegates
extension AppDelegate: MessagingDelegate, UNUserNotificationCenterDelegate {

    // Called when APNs registration succeeds → set APNs token and fetch FCM token
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard Constants.kFirebasePushEnabled else { return }

        Messaging.messaging().apnsToken = deviceToken
        print("APNs token set (length=\(deviceToken.count))")

        Messaging.messaging().token { token, error in
            if let error = error {
                print("FCM token fetch error (after APNs set):", error)
                UserDefaults.standard.set("", forKey: "FirebaseID")
            } else if let token = token {
                print("FCM token:", token)
                UserDefaults.standard.set(token, forKey: "FirebaseID")
                NotificationCenter.default.post(
                    name: Notification.Name("FCMTokenReceived"),
                    object: nil,
                    userInfo: ["token": token]
                )
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs registration failed:", error.localizedDescription)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM token (delegate refresh):", token)
        UserDefaults.standard.set(token, forKey: "FirebaseID")
        NotificationCenter.default.post(
            name: Notification.Name("FCMTokenReceived"),
            object: nil,
            userInfo: ["token": token]
        )
    }

    // Foreground notification presentation
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    // User tapped a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Tapped notification payload:", userInfo)
        completionHandler()
    }

    // Optional: background/silent
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Remote notification (bg/silent):", userInfo)
        completionHandler(.newData)
    }
}
