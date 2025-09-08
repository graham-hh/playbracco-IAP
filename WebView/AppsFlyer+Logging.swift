//
//  AppsFlyer+Logging.swift
//

import Foundation
#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

enum AFEventName {
    // Bottom tab selections
    static let tabHome       = "tabbar_home_selected"
    static let tabLiveNow    = "tabbar_live_now_selected"
    static let tabPlaySlip   = "tabbar_play_slip_selected"
    static let tabCasino     = "tabbar_casino_selected"

    // Example web actions
    static let webLogin      = "web_login_clicked"
    static let webJoin       = "web_join_now_clicked"
    static let webCTAClick   = "web_cta_clicked"
    static let webScreenView = "web_screen_view"
}

enum AFLog {
    static func event(_ name: String, _ values: [String: Any] = [:]) {
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent(name: name, values: values)
        #else
        // No-op if AppsFlyer isn’t in this build
        #endif
    }
}
