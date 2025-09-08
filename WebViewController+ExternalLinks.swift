//
//  WebViewController+ExternalLinks.swift
//  Intercept certain links/buttons and open in browser
//

import UIKit
import WebKit
import SafariServices

// Configure which URLs should open externally
private enum ExternalLinkConfig {
    // Any URL that contains one of these substrings will be opened externally
    static let urlSubstringsToOpenExternally: [String] = [
        "https://bracco.linepros.com/en?t=deposits",          // example
        "deposits",         // example
    ]

    // Choose how to open: true = SFSafariViewController (in-app), false = Safari app
    static let useInAppSafari = false
}

extension WebViewController {
    // Ensure the delegate is set once your webView exists.
    // If you already set it elsewhere, you can skip this convenience.
    @objc func wvg_enableExternalLinkInterceptionIfNeeded() {
        webView?.navigationDelegate = self
        // Optional: inject JS to convert button clicks to a special URL you can catch
        injectButtonHookIfNeeded()
    }

    // Intercept navigations
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let absolute = url.absoluteString

        // 1) Catch a custom scheme we might set from JS (e.g., "special-button://open")
        if url.scheme == "special-button" {
            openExternally(url: URL(string: "https://example.com/your-target")!) // map it to a real web URL
            decisionHandler(.cancel)
            return
        }

        // 2) Catch normal web URLs that match our patterns
        if ExternalLinkConfig.urlSubstringsToOpenExternally.contains(where: { absolute.contains($0) }) {
            openExternally(url: url)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    // MARK: - Helpers

    private func openExternally(url: URL) {
        if ExternalLinkConfig.useInAppSafari {
            // In-app browser sheet
            let vc = SFSafariViewController(url: url)
            vc.dismissButtonStyle = .close
            vc.modalPresentationStyle = .formSheet
            present(vc, animated: true, completion: nil)
        } else {
            // Open Safari app
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    /// Optional: inject a tiny JS hook to turn a button click into a custom URL we can intercept.
    /// Edit the selector ('#myButton') or add more as needed.
    private func injectButtonHookIfNeeded() {
        guard let webView = self.webView else { return }

        let js = """
        (function(){
          var b = document.querySelector('#myButton'); // <- change this to your button
          if (!b) { return; }
          b.addEventListener('click', function(e){
            e.preventDefault();
            window.location.href = 'special-button://open';
          }, { once: false });
        })();
        """

        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
