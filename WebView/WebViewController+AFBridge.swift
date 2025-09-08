//
//  WebViewController+AFBridge.swift
//

import Foundation
import WebKit

// Keep the JS bridge name in one place
private let afBridgeName = "af_event"

// Strongly retain the handler via associated object so it doesn't deallocate
private var _afHandlerKey: UInt8 = 0
private func setAssoc(_ obj: AnyObject, _ key: UnsafeRawPointer, _ value: Any?) {
    objc_setAssociatedObject(obj, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}
private func getAssoc<T>(_ obj: AnyObject, _ key: UnsafeRawPointer) -> T? {
    return objc_getAssociatedObject(obj, key) as? T
}

// A tiny standalone handler so the view controller doesn't have to conform
private final class AFScriptHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == afBridgeName else { return }

        // Expecting { name: String, params: Object }
        if let dict = message.body as? [String: Any],
           let name = dict["name"] as? String {

            let params = dict["params"] as? [String: Any] ?? [:]

            // Optional normalization of common web events
            let normalizedName: String
            switch name {
            case "login":               normalizedName = AFEventName.webLogin
            case "join_now", "signup":  normalizedName = AFEventName.webJoin
            case "cta_click":           normalizedName = AFEventName.webCTAClick
            case "web_screen_view":     normalizedName = AFEventName.webScreenView
            default:                    normalizedName = name
            }

            AFLog.event(normalizedName, params)
        }
    }
}

extension WebViewController {
    /// Call this once after `webView` is created (e.g., in `viewDidLoad`)
    @objc func wvg_installAFBridge() {
        guard let webView = self.webView else { return }

        // 1) Inject a tiny JS helper to capture clicks on elements tagged with data-af-event
        let source = """
        (function() {
          if (window.__afBridgeInstalled) return;
          window.__afBridgeInstalled = true;

          function tryParseJSON(s) {
            try { return JSON.parse(s); } catch (e) { return null; }
          }

          function payloadFromEl(el) {
            var name = el.getAttribute && el.getAttribute('data-af-event');
            if (!name) return null;
            var paramsRaw = el.getAttribute('data-af-params');
            var params = {};
            if (paramsRaw) {
              var js = tryParseJSON(paramsRaw);
              if (js && typeof js === 'object') params = js;
            }
            return { name: name, params: params };
          }

          function sendAF(payload) {
            try {
              window.webkit.messageHandlers.\(afBridgeName).postMessage(payload);
            } catch (e) {}
          }

          // Click handler walks up the DOM to find the first element with data-af-event
          document.addEventListener('click', function(e) {
            var el = e.target;
            while (el && el !== document) {
              if (el.hasAttribute && el.hasAttribute('data-af-event')) {
                var p = payloadFromEl(el);
                if (p) sendAF(p);
                break;
              }
              el = el.parentNode;
            }
          }, true);

          // Optional: a global function for manual logging from SPA code
          window.AF_LOG = function(name, params) {
            if (!name) return;
            sendAF({ name: name, params: params || {} });
          };
        })();
        """

        let script = WKUserScript(source: source,
                                  injectionTime: .atDocumentEnd,
                                  forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)

        // 2) Install our dedicated handler object (and retain it)
        let handler = AFScriptHandler()
        webView.configuration.userContentController.add(handler, name: afBridgeName)
        setAssoc(self, &_afHandlerKey, handler) // retain for the lifetime of this VC
    }
}
