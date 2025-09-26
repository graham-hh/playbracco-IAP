
//
//  WebViewController+AFBridge.swift
//

import Foundation
import WebKit

// Keep the JS bridge name in one place
private let afBridgeName = "af_event"

// Strongly retain the handler via associated object so it doesn't deallocate
private var _afHandlerKey: UInt8 = 0

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

        // 2) Register dedicated handler for afBridgeName messages
        let afHandler = AFBridgeHandler(owner: self)
        setAssoc(self, &_afHandlerKey, afHandler) // retain so it isn’t deallocated
        webView.configuration.userContentController.add(afHandler, name: afBridgeName)
    }

    internal func handleAFBridgeEvent(_ message: WKScriptMessage) {
        guard message.name == afBridgeName else { return }
        // Expecting { name: String, params: Object }
        if let dict = message.body as? [String: Any],
           let name = dict["name"] as? String {
            let params = dict["params"] as? [String: Any] ?? [:]
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
