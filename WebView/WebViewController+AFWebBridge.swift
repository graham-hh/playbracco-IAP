//
//  WebViewController+AFWebBridge.swift
//  Injects a JS click tracker (Login / Join) and forwards events to AppsFlyer.
//  Call `wvg_installAFBridgeAfterPageLoad()` after each page load.
//  Optionally call `wvg_logIfAuthURL(_:)` inside your nav delegate.
//
import UIKit
import WebKit
import ObjectiveC

#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

// MARK: - Private associated flag (so we only add the message handler once)
private var _afBridgeInstalledKey: UInt8 = 0

private func af_getInstalled(_ obj: AnyObject) -> Bool {
    (objc_getAssociatedObject(obj, &_afBridgeInstalledKey) as? NSNumber)?.boolValue ?? false
}
private func af_setInstalled(_ obj: AnyObject, _ value: Bool) {
    objc_setAssociatedObject(obj, &_afBridgeInstalledKey, NSNumber(value: value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

extension WebViewController {

    /// Call this AFTER a page finishes loading (e.g. from your existing didFinish).
    /// It installs the native message handler (once) and injects the JS click listeners.
    @objc public func wvg_installAFBridgeAfterPageLoad() {
        guard let webView = self.webView else { return }
        // 1) Install the message handler exactly once
        if !af_getInstalled(self) {
            webView.configuration.userContentController.add(self, name: "afBridge")
            af_setInstalled(self, true)
        }
        // 2) Inject/update click trackers on this page
        wvg_injectAFClickTrackers()
    }

    /// Inject JavaScript that listens for clicks on Login / Join and posts to native.
    private func wvg_injectAFClickTrackers() {
        let js = """
        (function(){
          if (window.__afBridgeInstalled) return;
          window.__afBridgeInstalled = true;

          function post(name, extra){
            try {
              window.webkit.messageHandlers.afBridge.postMessage(
                Object.assign({ name: name, ts: Date.now(), path: location.pathname, href: location.href }, extra || {})
              );
            } catch(e) {}
          }

          // Delegate click handling so it works with future DOM changes too
          document.addEventListener('click', function(e){
            let el = e.target;
            while (el && !(el.tagName === 'A' || el.tagName === 'BUTTON')) { el = el.parentElement; }
            if (!el) return;

            var txt = (el.textContent || '').trim().toLowerCase();
            var cls = (el.className || '').toString().toLowerCase();
            var id  = (el.id || '').toString().toLowerCase();
            var href = (el.href || '');

            // Heuristics — adjust to your site for best accuracy
            var isLogin = /login|sign\\s*in/.test(txt) || /login|signin/.test(id) || /login|signin/.test(cls) || /login|signin/i.test(href);
            var isJoin  = /join\\s*now|sign\\s*up|register/.test(txt) || /join|signup|register/.test(id) || /join|signup|register/.test(cls) || /join|signup|register/i.test(href);

            if (isLogin)  post('web_login_click',  { element: el.tagName, targetHref: href });
            if (isJoin)   post('web_join_click',   { element: el.tagName, targetHref: href });
          }, true);
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Receives messages from the injected JS and logs AppsFlyer events.
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "afBridge" else { return }
        #if canImport(AppsFlyerLib)
        guard let payload = message.body as? [String: Any],
              let name = payload["name"] as? String else { return }

        let eventName: String
        switch name {
        case "web_login_click": eventName = "af_web_login_click"
        case "web_join_click":  eventName = "af_web_join_click"
        default:                eventName = "af_web_other_click"
        }

        // Send the payload through so you get context (href, path, ts, etc.)
        AppsFlyerLib.shared().logEvent(name: eventName, values: payload)
        #endif
    }

    // MARK: - Optional fallback: log when navigation points to login/join URLs (no JS required)
    /// Call this inside your existing navigation delegate when you have a URL (e.g. decidePolicyFor).
    @objc public func wvg_logIfAuthURL(_ url: URL) {
        #if canImport(AppsFlyerLib)
        let s = url.absoluteString.lowercased()
        if s.contains("/login") || s.contains("signin") {
            AppsFlyerLib.shared().logEvent(name: "af_web_login_nav", values: ["url": s])
        }
        if s.contains("/join") || s.contains("signup") || s.contains("register") {
            AppsFlyerLib.shared().logEvent(name: "af_web_join_nav", values: ["url": s])
        }
        #endif
    }
}
