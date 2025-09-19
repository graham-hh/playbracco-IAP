import WebKit

// MARK: - WKScriptMessageHandler (App Bridge)
extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "flutter_inappwebview" {
            if let body = message.body as? [String: Any],
               let action = body["action"] as? String {
                print("Received action from web: \(action), body: \(body)")
            } else {
                print("flutter_inappwebview message but body not dictionary:", message.body)
            }
        }
        else if message.name == "afBridge" {
            handleAFBridgeEvent(message)
        }
        else if message.name == "mode", let mode = message.body as? String {
            print("Mode updated to:", mode)
            UserManager.shared.isRookieMode = (mode == "rookie")
        }
        else if message.name == "login", let loginState = message.body as? String {
            print("Login state:", loginState)
        }
    }
}
