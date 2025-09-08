//
//  WebViewController+CUIDBridge.swift
//  CUID bridge: let the web app set AppsFlyer customerUserID.
//

import UIKit
import WebKit

#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

// Simple flag so we don't install the bridge twice
private var _cuidBridgeInstalledKey: UInt8 = 0

extension WebViewController: WKScriptMessageHandler {

    /// Call this once after the webView exists (e.g., in viewDidLoad or when page finishes).
    @objc func wvg_installCUIDBridge() {
        // Already installed?
        if let installed = objc_getAssociatedObject(self, &_cuidBridgeInstalledKey) as? Bool, installed { return }
        guard let webView = self.webView else { return }

        // 1) Add the message handlers
        let controller = webView.configuration.userContentController
        controller.add(self, name: "setUserID")
        controller.add(self, name: "clearUserID")

        // 2) (Optional) Inject a small helper so you can call it easily from JS
        let js = """
        window.AFBridge = window.AFBridge || {};
        window.AFBridge.setUserID = function(id){ 
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.setUserID) {
            window.webkit.messageHandlers.setUserID.postMessage(String(id || ''));
          }
        };
        window.AFBridge.clearUserID = function(){ 
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.clearUserID) {
            window.webkit.messageHandlers.clearUserID.postMessage('');
          }
        };
        """
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        controller.addUserScript(userScript)

        objc_setAssociatedObject(self, &_cuidBridgeInstalledKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        print("CUID bridge installed")
    }

    // Receive messages from JS
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "setUserID":
            if let id = message.body as? String {
                wvg_applyCUIDFrom(id)
            } else {
                print("setUserID: invalid payload (expected string)")
            }

        case "clearUserID":
            wvg_clearCUID()

        default:
            break
        }
    }

    // Apply and persist the CUID
    @objc func wvg_applyCUIDFrom(_ rawId: String) {
        // Trim + basic sanity (AppsFlyer allows fairly free-form; you can tighten if you want)
        let id = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            print("setUserID: empty id ignored")
            return
        }

        // Persist (so it survives relaunch)
        UserDefaults.standard.set(id, forKey: "customUserID")

        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().customerUserID = id
        print("AppsFlyer CUID set to:", id)
        #else
        print("AppsFlyer not available; saved CUID:", id)
        #endif
    }

    // Clear the CUID (optional helper)
    @objc func wvg_clearCUID() {
        UserDefaults.standard.removeObject(forKey: "customUserID")
        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().customerUserID = nil
        print("AppsFlyer CUID cleared")
        #else
        print("CUID cleared (AppsFlyer not available)")
        #endif
    }
}
