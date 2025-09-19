import WebKit

// MARK: - WKScriptMessageHandler (App Bridge)
extension WebViewController: WKScriptMessageHandler {
    private static var lastLoginState: String?
    private static var lastMode: String?

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
            if WebViewController.lastMode != mode {
                WebViewController.lastMode = mode
                print("Mode updated to:", mode)
                UserManager.shared.isRookieMode = (mode == "rookie")
            }
        }
        else if message.name == "login", let loginState = message.body as? String {
            if WebViewController.lastLoginState != loginState {
                WebViewController.lastLoginState = loginState
                print("Login state:", loginState)
            }
        }
        else if message.name == "balances",
                let body = message.body as? [String: Any],
                let balances = body["balances"] as? [String: Any],
                let selectedId = body["selectedBalance"] as? Int,
                let selectedBalance = balances["\(selectedId)"] as? [String: Any],
                let isFreePlay = selectedBalance["isFreePlay"] as? Bool {
            
            let mode = isFreePlay ? "rookie" : "pro"
            let balanceAmount = selectedBalance["availableBalance"] as? Double ?? 0.0
            if WebViewController.lastMode != mode {
                WebViewController.lastMode = mode
                print("Mode detected from balances:", mode, "| Balance:", balanceAmount)
                UserManager.shared.isRookieMode = isFreePlay
            }
        }
    }
}
