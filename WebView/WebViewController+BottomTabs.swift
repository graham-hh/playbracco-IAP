//
//  WebViewController+BottomTabs.swift
//  Bottom UITabBar for WebViewGold — gated by URL, styled, hide-on-scroll, full-hide + snappy fade.
//

import UIKit
import WebKit
import ObjectiveC
import Foundation


#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif


// MARK: - 🔧 STYLE CONFIG (edit these)
private enum BottomTabStyle {
    // Colors
    static let backgroundColor: UIColor = UIColor(red: 1.06, green: 0.34, blue: 0.13, alpha: 1.0)
    static let selectedColor: UIColor   = .white
    static let unselectedColor: UIColor = UIColor(red: 0.34, green: 0.09, blue: 0.0, alpha: 1.0)

    // Typography
    static let selectedFont: UIFont = UIFont(name: "JetBrainsMono-Bold", size: 11)
        ?? .systemFont(ofSize: 11, weight: .semibold)
    static let normalFont: UIFont   = UIFont(name: "JetBrainsMono-Bold", size: 11)
        ?? .systemFont(ofSize: 11, weight: .regular)

    // Layout
    static let height: CGFloat = UIScreen.main.bounds.height * 0.1 // ~10% of screen height
    static let isTranslucent: Bool   = false
    static let hideLabels: Bool      = false

    // Extra space under page content so it never sits under the bar
    static let extraContentPadding: CGFloat = 2
    static let miniSlipExtraPadding: CGFloat = 0

    // Decoration
    static let showsTopDivider: Bool = true
}

// MARK: - Associated-object storage
private var _hasSetupTabsKey: UInt8   = 0
private var _tabBarKey: UInt8         = 0
private var _scrollObsKey: UInt8      = 0
private var _isBarHiddenKey: UInt8    = 0
private var _lastOffsetYKey: UInt8    = 0
private var _modalPollTimerKey: UInt8 = 0
private var _lastSelectedIndexKey: UInt8 = 0
var _pageChangedBridgeKey: UInt8 = 0
private var _modeBridgeKey: UInt8 = 0
private var _loginBridgeKey: UInt8 = 0

// Helpers
func getAssoc(_ obj: AnyObject, _ key: UnsafeRawPointer) -> Any? {
    return objc_getAssociatedObject(obj, key)
}
func setAssoc(_ obj: AnyObject, _ key: UnsafeRawPointer, _ value: Any?) {
    objc_setAssociatedObject(obj, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}



// MARK: - Tabs
private struct BottomTabItem {
    let title: String
    let systemImageName: String
    let urlString: String? // nil means "native action"
}

private let tabMap: [BottomTabItem] = [
    .init(title: "Sports",    systemImageName: "american.football", urlString: nil),
    .init(title: "In Play",   systemImageName: "stopwatch",         urlString: nil),
    .init(title: "Casino",    systemImageName: "dice",              urlString: nil),
    .init(title: "Shop",      systemImageName: "cart",              urlString: nil)  // ← NEW
]

// MARK: - When to show the bottom tabs
private let allowedExactURLs: [String] = [
    "https://mobile.playbracco.com/en"
]
private let allowedHost = "mobile.playbracco.com"
private let allowedPathPrefixes: [String] = [
    "/en"
]
private let allowedRegexPattern: String? = nil

private func shouldShowTabs(for url: URL?) -> Bool {
    guard let url = url else { return false }

    if allowedExactURLs.contains(url.absoluteString) {
        print("WVG BottomTabs: shouldShowTabs -> true (exact match)")
        return true
    }
    if url.host == allowedHost {
        if allowedPathPrefixes.isEmpty {
            print("WVG BottomTabs: shouldShowTabs -> true (host/path)")
            return true
        }
        if allowedPathPrefixes.contains(where: { url.path.hasPrefix($0) }) {
            print("WVG BottomTabs: shouldShowTabs -> true (host/path)")
            return true
        }
    }
    if let pattern = allowedRegexPattern,
       let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
        let s = url.absoluteString
        let range = NSRange(location: 0, length: (s as NSString).length)
        if regex.firstMatch(in: s, options: [], range: range) != nil {
            print("WVG BottomTabs: shouldShowTabs -> true (regex)")
            return true
        }
    }
    print("WVG BottomTabs: shouldShowTabs -> false for \(url.absoluteString)")
    return false
}

// MARK: - Behavior
extension WebViewController: UITabBarDelegate {
    // Lightweight on-screen debug toast (helps when console is quiet)
    private func wvg_debugToast(_ text: String) {
        DispatchQueue.main.async {
            let tag = 987_654
            // Reuse if already on screen
            if let old = self.view.viewWithTag(tag) {
                old.removeFromSuperview()
            }
            let label = UILabel()
            label.tag = tag
            label.text = text
            label.textAlignment = .center
            label.textColor = .white
            label.numberOfLines = 2
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            label.layer.cornerRadius = 10
            label.layer.masksToBounds = true
            label.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(label)
            let guide = self.view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -BottomTabStyle.height - 12),
                label.widthAnchor.constraint(lessThanOrEqualTo: guide.widthAnchor, multiplier: 0.9)
            ])
            label.alpha = 0
            UIView.animate(withDuration: 0.18) { label.alpha = 1 }
            UIView.animate(withDuration: 0.25, delay: 1.3, options: []) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
    /// Injects CSS/JS tweaks for page UI:
    /// - Hides hamburger (.MuiStack-root.css-10zb6m2)
    /// - Hides footer (.MuiBox-root.css-14qa6pm)
    /// - Hides "Purchase Bracco Coins" button (by data-testid and text fallback)
    /// - Installs a MutationObserver to keep rules active
    private func wvg_applyPageHacks() {
        guard let webView = self.webView else { return }
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let js = """
        (function(){
          try {
            var id = 'wvg-css';
            var __WVG_IS_IPAD__ = \(isPad ? "true" : "false");
            var cssText = `
              /* Hide hamburger menu */
              .MuiStack-root.css-10zb6m2 { display: none !important; }
              /* Hide additional top-left stack */
              .MuiStack-root.css-1ev73j9 { display: none !important; }

              /* Hide small footer under bet slip */
              .MuiBox-root.css-14qa6pm {
                display: none !important;
                height: 0 !important;
                visibility: hidden !important;
                overflow: hidden !important;
              }

              /* Hide "Purchase Bracco Coins" button by data-testid */
              button[data-testid="account-dropdown-button"] { display: none !important; }

              /* Hide LiveAgent/LaDesk floating chat widget */
              [id^="b_"][style*="position: fixed"],
              .circleContactButtonWrap,
              .circleContactBack,
              .circleContactLeft,
              .circleContactRight,
              .circleContactTop,
              .circleContactBottom,
              .ladesk-widget,
              [class*="ladesk" i],
              [class*="liveagent" i],
              #LPMcontainer,
              #lpChat,
              iframe[src*="ladesk.com" i],
              iframe[src*="liveagent" i] {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
                width: 0 !important;
                height: 0 !important;
                opacity: 0 !important;
              }
              /* Extra targets for LaDesk/LiveAgent variants */
              div[title="Live chat button"],
              [id^="icb_"],
              iframe[id^="icb_"],
              iframe[src*="generateWidget.php" i],
              iframe[src*="ladesk" i] {
                display: none !important;
                visibility: hidden !important;
                pointer-events: none !important;
                width: 0 !important;
                height: 0 !important;
                opacity: 0 !important;
              }
            `;

            var style = document.getElementById(id);
            if (!style) {
              style = document.createElement('style');
              style.id = id;
              style.type = 'text/css';
              (document.head || document.documentElement).appendChild(style);
            }
            if (style.textContent !== cssText) {
              style.textContent = cssText;
            }

            // Fallback: hide the button by visible text (in case data-testid changes)
            function hideBuyCoinsByText(){
              try {
                var nodes = Array.from(document.querySelectorAll('button, [role="button"]'));
                nodes.forEach(function(btn){
                  var txt = (btn.innerText || '').trim().toLowerCase();
                  if (txt.includes('purchase bracco coins')) {
                    btn.style.setProperty('display','none','important');
                  }
                });
              } catch(e){}
            }

            function hideLiveAgent(){
              try {
                var selectors = [
                  '[id^="b_"][style*="position: fixed"]',
                  'div[title="Live chat button"]',
                  '[id^="icb_"]',
                  'iframe[id^="icb_"]',
                  '.circleContactButtonWrap',
                  '.circleContactBack', '.circleContactLeft', '.circleContactRight', '.circleContactTop', '.circleContactBottom',
                  '.ladesk-widget',
                  '[class*="ladesk" i]',
                  '[class*="liveagent" i]',
                  '#LPMcontainer', '#lpChat',
                  'iframe[src*="ladesk.com" i]',
                  'iframe[src*="generateWidget.php" i]',
                  'script[src*="ladesk.com" i]'
                ];
                selectors.forEach(function(sel){
                  try {
                    document.querySelectorAll(sel).forEach(function(n){
                      // Prefer removing the floating button and up to two wrapper levels
                      var target = n;
                      for (var i = 0; i < 3 && target; i++) {
                        if (target && target.parentNode) {
                          // If wrapper looks like the floating chat container, remove it
                          if ((target.id && (target.id.indexOf('b_') === 0 || target.id.indexOf('icb_') === 0)) ||
                              (target.getAttribute && target.getAttribute('title') === 'Live chat button')) {
                            try { target.parentNode.removeChild(target); } catch(e) {}
                            break;
                          }
                        }
                        target = target.parentNode;
                      }
                      // If still present, hard-hide it
                      if (n && n.isConnected) {
                        if (n.style) {
                          n.style.setProperty('display','none','important');
                          n.style.setProperty('visibility','hidden','important');
                          n.style.setProperty('pointer-events','none','important');
                          n.style.setProperty('opacity','0','important');
                          n.style.setProperty('width','0','important');
                          n.style.setProperty('height','0','important');
                        }
                        try { if (n.parentNode) n.parentNode.removeChild(n); } catch(e) {}
                      }
                    });
                  } catch(e){}
                });
              } catch(e){}
            }
            hideBuyCoinsByText();
            hideLiveAgent();

            // Keep tweaks active on dynamic DOM changes
            if (!window.__wvgHacksObserver__) {
              window.__wvgHacksObserver__ = new MutationObserver(function(){
                hideBuyCoinsByText();
                hideLiveAgent();
              });
              window.__wvgHacksObserver__.observe(document.documentElement, {
                subtree: true,
                childList: true,
                attributes: true,
                attributeFilter: ['class','style']
              });
            }
            return true;
          } catch(e) { return false; }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - Bottom padding helpers for page content (instance methods)
    private func wvg_currentBottomPaddingPixels() -> Int {
        let safeBottom = self.view.window?.safeAreaInsets.bottom ?? self.view.safeAreaInsets.bottom
        let barHeight = self.bottomTabBar?.frame.height ?? 0
        let pad = barHeight + safeBottom
        return max(0, Int(ceil(pad)))
    }

    /// Inject / update bottom padding for fixed/sticky elements only; do NOT add html/body padding or spacer div.
    private func wvg_setPageBottomPadding(visible: Bool) {
        guard let webView = self.webView else { return }
        let px = visible ? wvg_currentBottomPaddingPixels() : 0
        let js = """
        (function(px){
          try {
            // Do NOT add body/html padding or spacer elements (prevents double "extra space")
            // Only lift fixed/sticky elements above the native tab bar.
            var selectors = [
              '.sidebar-right','.BetSlipTopContainer','.betslip-min','.betslip--min','.betslip','.bet-slip',
              '.tab.selected.minimized','.tab--selected.minimized','.tab.minimized',
              '[data-testid*="slip"]','[data-testid*="betslip"]','[class*="betslip"]','[class*="bet-slip"]',
              '[class*="sticky"]','[class*="bottom"]','[class*="footer"]','footer',
              '*[style*="position:fixed"][style*="bottom:0"]'
            ];
            var seen = new Set();
            selectors.forEach(function(sel){
              try {
                document.querySelectorAll(sel).forEach(function(n){
                  if (seen.has(n)) return;
                  var cs = window.getComputedStyle(n);
                  if (cs.position === 'fixed' || cs.position === 'sticky') {
                    n.style.bottom = (px)+'px';
                    n.style.zIndex = '2147483646';
                  }
                  seen.add(n);
                });
              } catch(e){}
            });
            return true;
          } catch(e) { return false; }
        })(\(px));
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Remove any extra top padding/margins the page might have accumulated.
    private func wvg_resetTopPadding() {
        guard let webView = self.webView else { return }
        let js = """
        (function(){
          try {
            // Remove our previous top style if it exists
            var el = document.getElementById('wvg-top-padding');
            if (el && el.parentNode) el.parentNode.removeChild(el);

            // Zero out common containers that may have inline top space
            var nodes = [
              'html','body','#root','#app','header','.header',
              '.topbar','.navbar','[data-testid="header"]',
              '.header-container', '.headerContainer', '#header-container', '#headerContainer',
              '.header.container', '[class*="header"][class*="container"]'
            ];
            nodes.forEach(function(sel){
              try {
                var n = document.querySelector(sel);
                if (!n) return;
                var s = n.style;
                // only touch if explicitly set (don’t override site CSS classes)
                if (s && (s.paddingTop || s.marginTop)) {
                  s.paddingTop = '0px';
                  s.marginTop = '0px';
                }
              } catch(e){}
            });
            return true;
          } catch(e) { return false; }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Continuously clamp any top padding/margin that the site may (re)apply so the iOS status bar / top chrome never gets pushed off-screen.
    private func wvg_watchAndClampTopPadding() {
        guard let webView = self.webView else { return }
        let js =
        """
        (function(){
          try {
            // If already installed, do nothing
            if (window.__wvgTopClampInstalled__) return true;
            window.__wvgTopClampInstalled__ = true;

            var CLAMP_MAX = 0; // do not allow any extra top padding/margin beyond 0
            var targets = ['html','body','#root','#app','.app','main','header','.header','.topbar','.navbar','[data-testid="header"]', '.header-container', '.headerContainer', '#header-container', '#headerContainer', '.header.container', '[class*="header"][class*="container"]'];

            function clampTopStyles(node){
              try{
                if (!node || !(node instanceof HTMLElement)) return;
                var cs = window.getComputedStyle(node);
                // Only clamp if computed values are pushing content down
                var pt = parseFloat(cs.paddingTop)||0;
                var mt = parseFloat(cs.marginTop)||0;
                if (pt > CLAMP_MAX) node.style.paddingTop = '0px';
                if (mt > CLAMP_MAX) node.style.marginTop = '0px';
                // guard against 'top' offset on fixed/sticky headers
                if ((cs.position === 'fixed' || cs.position === 'sticky') && parseFloat(cs.top)||0 > 0) {
                  node.style.top = '0px';
                }
              }catch(e){}
            }

            function clampAll(){
              targets.forEach(function(sel){
                try {
                  var n = document.querySelector(sel);
                  if (n) clampTopStyles(n);
                } catch(e){}
              });
            }

            // Initial pass
            clampAll();

            // Observe changes that might re-introduce top spacing
            var mo = new MutationObserver(function(muts){
              clampAll();
            });
            mo.observe(document.documentElement, {attributes:true,childList:true,subtree:true,attributeFilter:['style','class']});

            // Also respond to resize/scroll which some UIs use to toggle classes
            window.addEventListener('resize', clampAll, {passive:true});
            window.addEventListener('scroll', clampAll, {passive:true});

            return true;
          } catch(e) { return false; }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Kept so your AppDelegate's install call compiles safely.
    public static func installBottomTabsSwizzle() { }

    /// Call this from your existing `webView(_:didFinish:)`
    @objc public func wvg_handleDidFinish(_ webView: WKWebView) {
        print("WVG BottomTabs: didFinish url=\(webView.url?.absoluteString ?? "nil")")
        // Always apply UI hacks (hide hamburger/footer/buy-coins) if present
        wvg_applyPageHacks()

        // Inject JS to detect Rookie vs Pro mode and send to iOS app
        let detectModeJS = """
        (function() {
          try {
            if (window.__wvgModeIntervalInstalled__) {
              console.log("WVG Mode Detection: Interval already installed");
              return;
            }
            window.__wvgModeIntervalInstalled__ = true;
            function detectModeAndNotify() {
              try {
                var mode = null;
                var current = null;
                if (window.balances && window.selectedBalance !== undefined && window.selectedBalance !== null) {
                  current = window.balances[window.selectedBalance];
                  // Debug log: balances, selectedBalance, current
                  console.log("Mode check: balances=", window.balances, "selected=", window.selectedBalance, "current=", current);
                  if (current && current.name === "main") {
                    mode = "pro";
                  } else {
                    mode = "rookie";
                  }
                } else {
                  // Debug log even if balances/selectedBalance missing
                  console.log("Mode check: balances=", window.balances, "selected=", window.selectedBalance, "current=", current);
                }
                if (mode) {
                  // Only notify if mode changed (optional: could cache last mode)
                  if (!window.__wvgLastModeSent__ || window.__wvgLastModeSent__ !== mode) {
                    window.__wvgLastModeSent__ = mode;
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mode) {
                      window.webkit.messageHandlers.mode.postMessage(mode);
                    }
                    console.log("WVG Mode Detection: Detected mode:", mode);
                  }
                } else {
                  console.log("WVG Mode Detection: No mode detected");
                }
              } catch(e) {
                console.log("WVG Mode Detection: Error in detectModeAndNotify", e);
              }
            }
            // Initial detection
            detectModeAndNotify();
            // Re-run detection every few seconds
            window.__wvgModeInterval__ = setInterval(detectModeAndNotify, 3000);
            console.log("WVG Mode Detection: Interval installed");
          } catch(e) {
            console.log("WVG Mode Detection: Outer error", e);
          }
        })();
        """
        webView.evaluateJavaScript(detectModeJS, completionHandler: nil)


        // Inject JS to listen for pageChanged messages from the web app
        let pageChangedListenerJS = """
        (function() {
          try {
            if (!window.__wvgPageChanged__) {
              window.__wvgPageChanged__ = function(page) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.pageChanged) {
                  window.webkit.messageHandlers.pageChanged.postMessage(page);
                }
              };
            }
          } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(pageChangedListenerJS, completionHandler: nil)

        // Inject JS to detect mode from header and send to iOS app (robust retrying header detector, faster interval, clears on detect)
        let detectModeHeaderJS = """
        (function() {
          function detectModeFromHeader() {
            var el = document.querySelector('div.MuiStack-root.css-vrrilw');
            if (el && el.innerText) {
              var txt = el.innerText.toLowerCase();
              var mode = txt.includes('pro') ? 'pro' : 'rookie';
              if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mode) {
                window.webkit.messageHandlers.mode.postMessage(mode);
              }
              console.log("✅ Mode header detected quickly:", mode, "from text:", txt);
              if (window.__modeHeaderInterval__) {
                clearInterval(window.__modeHeaderInterval__);
                window.__modeHeaderInterval__ = null;
              }
            } else {
              console.log("⚠️ Mode header not found, retrying...");
            }
          }
          detectModeFromHeader();
          if (!window.__modeHeaderInterval__) {
            window.__modeHeaderInterval__ = setInterval(detectModeFromHeader, 400); // faster retry
          }
        })();
        """
        webView.evaluateJavaScript(detectModeHeaderJS, completionHandler: nil)

        // Inject JS to detect login state from header and send to iOS app (quick retrying header detector)
        let detectLoginHeaderJS = """
        (function() {
          function detectLoginFromHeader() {
            var loginBtn = document.querySelector('button[data-testid="login-button"]');
            var loggedIn = !(loginBtn && loginBtn.innerText && loginBtn.innerText.toLowerCase().includes('log in'));
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.login) {
              window.webkit.messageHandlers.login.postMessage(loggedIn ? "loggedIn" : "loggedOut");
            }
            console.log("✅ Login header detected:", loggedIn ? "loggedIn" : "loggedOut");
          }
          detectLoginFromHeader();
          if (!window.__loginHeaderInterval__) {
            window.__loginHeaderInterval__ = setInterval(detectLoginFromHeader, 400); // quick retry
          }
        })();
        """
        webView.evaluateJavaScript(detectLoginHeaderJS, completionHandler: nil)
        // Always register the "pageChanged" script message handler here
        let ucc = webView.configuration.userContentController
        ucc.removeScriptMessageHandler(forName: "pageChanged")
        let bridge = PageChangedBridge(owner: self)
        setAssoc(self, &_pageChangedBridgeKey, bridge)
        ucc.add(bridge, name: "pageChanged")


        // Only set up tabs once and only when URL matches rules
        if let done = getAssoc(self, &_hasSetupTabsKey) as? Bool, done { return }
        guard shouldShowTabs(for: webView.url) else { return }
        setupBottomTabs()
        setAssoc(self, &_hasSetupTabsKey, true as Bool?)
    }

    private func setupBottomTabs() {
        print("WVG BottomTabs: setupBottomTabs()")
        guard let webView = self.webView else { return }
        let ucc = webView.configuration.userContentController

        // Always remove before adding (idempotent)
        ucc.removeScriptMessageHandler(forName: "mode")
        let modeBridge = ModeBridge(owner: self)
        setAssoc(self, &_modeBridgeKey, modeBridge)
        ucc.add(modeBridge, name: "mode")

        ucc.removeScriptMessageHandler(forName: "login")
        let loginBridge = LoginBridge(owner: self)
        setAssoc(self, &_loginBridgeKey, loginBridge)
        ucc.add(loginBridge, name: "login")


        let bar = UITabBar(frame: .zero)
        bar.alpha = 0
        bar.delegate = self
        bar.translatesAutoresizingMaskIntoConstraints = false
        applyStyle(to: bar)

        var items: [UITabBarItem] = []
        for (idx, tab) in tabMap.enumerated() {
            let image: UIImage? = UIImage(systemName: tab.systemImageName)
            let title = BottomTabStyle.hideLabels ? nil : tab.title
            let item = UITabBarItem(title: title, image: image, tag: idx)
            if BottomTabStyle.hideLabels {
                item.title = nil
                item.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
            } else {
                item.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
            }
            items.append(item)
        }
        // Hide Shop tab if user is not logged in
        let isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        if !isLoggedIn {
            items = items.filter { $0.title != "Shop" }
        }
        bar.items = items
        bar.selectedItem = items.first
        // Track last selected index (start on 0)
        setAssoc(self, &_lastSelectedIndexKey, NSNumber(value: 0))
        // Ensure delegate remains set
        bar.delegate = self

        view.addSubview(bar)
        setAssoc(self, &_tabBarKey, bar)

        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.1)
        ])

        // Physically pin the web view above the tab bar
        reanchorWebViewBottom(to: bar)

        if BottomTabStyle.showsTopDivider {
            let topLine = UIView()
            topLine.translatesAutoresizingMaskIntoConstraints = false
            topLine.backgroundColor = .white
            bar.addSubview(topLine)
            NSLayoutConstraint.activate([
                topLine.topAnchor.constraint(equalTo: bar.topAnchor),
                topLine.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
                topLine.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
                topLine.heightAnchor.constraint(equalToConstant: 2)
            ])
            bar.bringSubviewToFront(topLine)
        }

        view.layoutIfNeeded()
        bar.transform = .identity
        bar.alpha = 1.0
        // WebView is now physically pinned above the bar; no extra bottom insets needed.
        applyWebViewInsets(forBarVisible: true) // this will zero bottom insets
        wvg_watchAndClampTopPadding()

        UIView.animate(withDuration: 0.30, delay: 0, options: [.curveEaseOut]) {
            bar.alpha = 1
        }
    }

    /// Physically pins the WKWebView's bottom to the tab bar's top so content never sits underneath.
    private func reanchorWebViewBottom(to bar: UITabBar) {
        guard let webView = self.webView else { return }
        webView.translatesAutoresizingMaskIntoConstraints = false

        // Deactivate any existing bottom constraints that pin the webView to the view/safe area bottom
        let toRemove = view.constraints.filter {
            // Constraints of the form: webView.bottom == view.safeArea.bottom OR view.bottom
            (($0.firstItem as? UIView) == webView && $0.firstAttribute == .bottom)
            || (($0.secondItem as? UIView) == webView && $0.secondAttribute == .bottom)
        } + webView.constraints.filter {
            // Constraints internal to the webView referencing its bottom (defensive)
            $0.firstAttribute == .bottom || $0.secondAttribute == .bottom
        }
        NSLayoutConstraint.deactivate(toRemove)

        // Ensure the web view is anchored on top, leading, trailing as before (do not change if already set)
        if webView.topAnchor.constraint(equalTo: view.topAnchor).isActive == false &&
           webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive == false {
            // If no explicit top constraint exists, prefer safe area top
            if #available(iOS 11.0, *) {
                webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            } else {
                webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
            }
        }
        if webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive == false {
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        }
        if webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive == false {
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        }

        // Pin the webView's bottom to the TOP of the tab bar
        webView.bottomAnchor.constraint(equalTo: bar.topAnchor).isActive = true

        // Eliminate bottom content inset since the web view no longer sits under the bar
        webView.scrollView.contentInset.bottom = 0
        webView.scrollView.verticalScrollIndicatorInsets.bottom = 0
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        // Remove any JS-added bottom padding from earlier runsstill no
        wvg_setPageBottomPadding(visible: false)
    }

    private var bottomTabBar: UITabBar? {
        get { return getAssoc(self, &_tabBarKey) as? UITabBar }
        set { setAssoc(self, &_tabBarKey, newValue) }
    }
    private var modalPollTimer: Timer? {
        get { return getAssoc(self, &_modalPollTimerKey) as? Timer }
        set { setAssoc(self, &_modalPollTimerKey, newValue) }
    }

    /// Hide the native bar while a generic web "modal" is visible
    private func startModalDetector() {
        // Temporarily disabled to prevent false positives that hide the tab bar.
        stopModalDetector()
        return
    }

    private func stopModalDetector() {
        modalPollTimer?.invalidate()
        modalPollTimer = nil
    }

    /// Try to trigger a Linepros in-app action instead of navigating.
    /// It attempts (in order):
    ///  1) window.lp?.actions?.<function>()
    ///  2) window.postMessage({...}) / MessageEvent fallback
    ///  3) fallback URL navigation (if provided)
    private func lpTrigger(action: String,
                           params: [String: Any]? = nil,
                           fallbackURL: String? = nil) {
        guard let webView = self.webView else { return }

        // Safely JSON-encode params for JS
        let json: String
        if let p = params,
           let data = try? JSONSerialization.data(withJSONObject: p, options: []),
           let s = String(data: data, encoding: .utf8) {
            json = s
        } else {
            json = "{}"
        }

        // Map action -> function name (matches what your dev shared)
        let js = """
        (function(action, params){
          try {
            var act = (window.lp && window.lp.actions) ? window.lp.actions : null;
            function callIf(fn){ try { if (typeof fn === 'function') { fn(); return true; } } catch(e){} return false; }

            switch(action){
              case 'show-login':
                if (act && act.showLogin) return callIf(act.showLogin);
                break;
              case 'show-join':
                if (act && act.showJoin) return callIf(act.showJoin);
                break;
              case 'show-deposits':
                if (act && act.showDeposits) return callIf(act.showDeposits);
                break;
              case 'show-payouts':
                if (act && act.showPayouts) return callIf(act.showPayouts);
                break;
              case 'show-sport':
                if (act && params && params.partnerProduct === 'prematch' && act.showSports) {
                  return callIf(act.showSports);
                }
                if (act && params && params.partnerProduct === 'live' && act.showLiveBetting) {
                  return callIf(act.showLiveBetting);
                }
                break;
            }

            // If no direct API, try to emulate a banner click via postMessage
            var payload = { 'banner-click': { action: action, params: params || {} } };

            try { window.postMessage(payload, '*'); } catch(e) {}
            try {
              var ev = new MessageEvent('message', { data: payload });
              window.dispatchEvent(ev);
            } catch(e) {}

            return true;
          } catch(e) {
            return false;
          }
        })('\(action)', \(json));
        """

        webView.evaluateJavaScript(js) { [weak self] result, error in
            let ok = (result as? Bool) ?? (error == nil)
            if !ok, let urlStr = fallbackURL, let url = URL(string: urlStr) {
                self?.webView?.load(URLRequest(url: url))
            }
        }
    }

    // MARK: Tab actions
    // Removed shouldSelect (was not firing; not needed for UITabBarDelegate)

    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("WVG BottomTabs: didSelect tag=\(item.tag)")
        let idx = item.tag
        guard idx >= 0 && idx < tabMap.count else { return }

        // Read previously selected tab index (defaults to 0)
        let prevIndex = (getAssoc(self, &_lastSelectedIndexKey) as? NSNumber)?.intValue ?? 0

        // Intercept the Shop tab: present sheet or full screen and revert selection back to previous tab
        if idx == 3 {
            // Revert visual selection to previous (or first if out of range)
            if let items = tabBar.items, prevIndex >= 0, prevIndex < items.count {
                tabBar.selectedItem = items[prevIndex]
            } else {
                tabBar.selectedItem = tabBar.items?.first
                setAssoc(self, &_lastSelectedIndexKey, NSNumber(value: 0))
            }

            if UserManager.shared.isRookieMode {
                // Rookie -> show in-app purchases
                let shopVC = ShopViewController()
                shopVC.modalPresentationStyle = .pageSheet
                self.present(shopVC, animated: true, completion: nil)
            } else {
                // Pro -> external Pro shop
                self.presentProShop()
            }
            return
        }

        switch idx {
        case 0: // Sports (prematch)
            lpTrigger(action: "show-sport",
                      params: ["partnerProduct": "prematch"],
                      fallbackURL: tabMap[idx].urlString)

        case 1: // In Play (live)
            lpTrigger(action: "show-sport",
                      params: ["partnerProduct": "live"],
                      fallbackURL: tabMap[idx].urlString)

        case 2: // Casino
            lpTrigger(action: "show-sport",
                      params: ["partnerProduct": "casino"],
                      fallbackURL: nil)

        default:
            if let urlStr = tabMap[idx].urlString, let url = URL(string: urlStr) {
                self.setBarHidden(false, animated: true)
                webView?.load(URLRequest(url: url))
            }
        }

        // Persist the new selected index (not Shop)
        setAssoc(self, &_lastSelectedIndexKey, NSNumber(value: idx))

        // Re-apply UI hacks after potential navigation/action
        wvg_applyPageHacks()
    }


    // MARK: Insets helper
    private func applyWebViewInsets(forBarVisible visible: Bool) {
        guard let sv = webView?.scrollView else { return }
        // We now constrain the web view's frame to end at the tab bar's top.
        // So keep bottom insets at 0 to avoid extra blank space.
        sv.contentInset.bottom = 0
        sv.verticalScrollIndicatorInsets.bottom = 0

        // Ensure no extra top inset is applied by UIKit
        sv.contentInset.top = 0
        sv.scrollIndicatorInsets.top = 0
        sv.contentInsetAdjustmentBehavior = .never

        // Clear stray top padding the page might have applied
        wvg_resetTopPadding()
        // Keep clamping top spacing so headers don’t drift
        wvg_watchAndClampTopPadding()
    }

    // MARK: Style
    private func applyStyle(to bar: UITabBar) {
        // Explicitly set isTranslucent to false at the top
        bar.isTranslucent = false
        bar.tintColor = BottomTabStyle.selectedColor
        bar.unselectedItemTintColor = BottomTabStyle.unselectedColor
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = BottomTabStyle.backgroundColor
            appearance.backgroundEffect = nil
            appearance.stackedLayoutAppearance.selected.iconColor = BottomTabStyle.selectedColor
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.selectedColor,
                .font: BottomTabStyle.selectedFont
            ]
            appearance.stackedLayoutAppearance.normal.iconColor = BottomTabStyle.unselectedColor
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.unselectedColor,
                .font: BottomTabStyle.normalFont
            ]
            // Keep iPad inline/compactInline in sync
            appearance.inlineLayoutAppearance.normal.iconColor = BottomTabStyle.unselectedColor
            appearance.inlineLayoutAppearance.selected.iconColor = BottomTabStyle.selectedColor
            appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.unselectedColor,
                .font: BottomTabStyle.normalFont
            ]
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.selectedColor,
                .font: BottomTabStyle.selectedFont
            ]
            appearance.compactInlineLayoutAppearance.normal.iconColor = BottomTabStyle.unselectedColor
            appearance.compactInlineLayoutAppearance.selected.iconColor = BottomTabStyle.selectedColor
            appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.unselectedColor,
                .font: BottomTabStyle.normalFont
            ]
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: BottomTabStyle.selectedColor,
                .font: BottomTabStyle.selectedFont
            ]
            if BottomTabStyle.hideLabels {
                appearance.stackedLayoutAppearance.normal.titleTextAttributes[.foregroundColor] = UIColor.clear
                appearance.stackedLayoutAppearance.selected.titleTextAttributes[.foregroundColor] = UIColor.clear
                appearance.inlineLayoutAppearance.normal.titleTextAttributes[.foregroundColor] = UIColor.clear
                appearance.inlineLayoutAppearance.selected.titleTextAttributes[.foregroundColor] = UIColor.clear
                appearance.compactInlineLayoutAppearance.normal.titleTextAttributes[.foregroundColor] = UIColor.clear
                appearance.compactInlineLayoutAppearance.selected.titleTextAttributes[.foregroundColor] = UIColor.clear
            }
            // Prevent system blur by setting background/shadow images to blank
            bar.backgroundImage = UIImage()
            bar.shadowImage = UIImage()
            bar.standardAppearance = appearance
            if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = appearance }
        } else {
            bar.barTintColor = BottomTabStyle.backgroundColor
            // Prevent system blur by setting background/shadow images to blank
            bar.backgroundImage = UIImage()
            bar.shadowImage = UIImage()
        }
    }

    // MARK: Hide-on-scroll
    private func installHideOnScroll() {
        guard let scrollView = webView?.scrollView else { return }
        setAssoc(self, &_lastOffsetYKey, NSNumber(value: Double(scrollView.contentOffset.y)))
        let observation: NSKeyValueObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            guard let self = self else { return }
            self.handleScrollChange(scrollView: sv)
        }
        setAssoc(self, &_scrollObsKey, observation)
    }

    private func handleScrollChange(scrollView: UIScrollView) {
        guard bottomTabBar != nil else { return }
        let currentY = scrollView.contentOffset.y
        let lastNum = getAssoc(self, &_lastOffsetYKey) as? NSNumber
        let lastY = CGFloat(lastNum?.doubleValue ?? Double(currentY))
        let delta = currentY - lastY
        setAssoc(self, &_lastOffsetYKey, NSNumber(value: Double(currentY)))
        if abs(delta) < 2 { return }
        if currentY <= -scrollView.adjustedContentInset.top {
            setBarHidden(false, animated: true)
            return
        }
        setBarHidden(delta > 0, animated: true)
    }

    private func setBarHidden(_ hidden: Bool, animated: Bool) {
        // Always keep the bar visible; web view is physically pinned above it.
        if let bar = bottomTabBar {
            bar.transform = .identity
            bar.alpha = 1.0
        }
        applyWebViewInsets(forBarVisible: true) // keep bottom insets at 0
        setAssoc(self, &_isBarHiddenKey, NSNumber(value: false))
    }

    // MARK: - Play Slip Handling (kept for future, no changes needed now)

    /// JS helper: check if the slip is currently open
    private func isPlaySlipOpen(_ completion: @escaping (Bool) -> Void) {
        guard let webView = self.webView else { completion(false); return }
        let js =
        """
        (function(){
          var slip = document.querySelector('.sidebar-right');
          if (!slip) return false;
          var isOpenClass = slip.classList.contains('open');
          var isVisible = slip.style.display !== 'none' && slip.offsetParent !== null;
          return !!(isOpenClass || isVisible);
        })();
        """
        webView.evaluateJavaScript(js) { result, _ in
            completion((result as? Bool) ?? false)
        }
    }

    /// Open/expand the right sidebar (betslip) and hide the native tab bar
    private func wvg_openPlaySlip() {
        guard let webView = self.webView else { return }

        let js =
        """
        (function(){
          var slip = document.querySelector('.sidebar-right');
          if (slip) {
            var minimizedBtn = document.querySelector('.tab.selected.minimized, .tab--selected.minimized');
            if (minimizedBtn) { minimizedBtn.click(); return "clicked_minimized"; }

            var toggle = document.querySelector(
              '[data-testid*="slip"],.open-betslip,.betslip-button,.sidebar-toggle,button[aria-controls*="sidebar"],button[aria-label*="slip"],a[href*="slip"],.BetSlipButton'
            );
            if (toggle) { toggle.click(); return "clicked_toggle"; }

            slip.style.display = 'block';
            slip.style.position = 'fixed';
            slip.style.top = '0';
            slip.style.right = '0';
            slip.style.bottom = '0';
            slip.style.zIndex = '9999';
            slip.classList.add('open');
            return "forced_full";
          }
          return "no_target";
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
        setBarHidden(true, animated: true)
    }

    /// Close/collapse the right sidebar (betslip) and show the native tab bar
    private func wvg_closePlaySlip() {
        guard let webView = self.webView else { return }
        let js =
        """
        (function(){
          var slip = document.querySelector('.sidebar-right');
          if (slip) {
            var closeBtn = document.querySelector('.sidebar-right .close, .sidebar-right .icon-close, .sidebar-right [aria-label*="close"]');
            if (closeBtn) { closeBtn.click(); return "clicked_close"; }

            var selectedTab = document.querySelector('.tab.selected:not(.minimized), .tab--selected:not(.minimized)');
            if (selectedTab) { selectedTab.click(); return "clicked_selected"; }

            slip.classList.remove('open');
            slip.style.display = 'none';
            slip.style.position = '';
            slip.style.top = '';
            slip.style.right = '';
            slip.style.bottom = '';
            slip.style.zIndex = '';
            return "forced_hide";
          }
          return "none";
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
        setBarHidden(false, animated: true)
    }
}





// MARK: - PageChanged bridge handler (avoids duplicate WKScriptMessageHandler conformance)
final class PageChangedBridge: NSObject, WKScriptMessageHandler {
    weak var owner: WebViewController?
    init(owner: WebViewController) { self.owner = owner }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "pageChanged" else { return }
        guard let page = message.body as? String else { return }
        let p = page.lowercased()
        if p == "login" || p == "join" || p == "account" {
            owner?.hideBottomTabs()
        } else {
            owner?.showBottomTabs()
        }
    }
}

// MARK: - Login bridge handler
final class LoginBridge: NSObject, WKScriptMessageHandler {
    weak var owner: WebViewController?
    init(owner: WebViewController) { self.owner = owner }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "login",
              let state = message.body as? String else { return }

        let isLoggedIn = (state == "loggedIn")
        UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")

        DispatchQueue.main.async {
            self.owner?.updateShopTabVisibility(isLoggedIn: isLoggedIn)
        }
    }
}

// MARK: - Mode bridge handler
final class ModeBridge: NSObject, WKScriptMessageHandler {
    weak var owner: WebViewController?
    init(owner: WebViewController) { self.owner = owner }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "mode",
              let mode = message.body as? String else { return }

        let isRookie = (mode == "rookie")
        UserDefaults.standard.set(isRookie, forKey: "lastMode")
        UserManager.shared.isRookieMode = isRookie

        print("🎮 ModeBridge: Detected mode =", mode)
    }
}

extension WebViewController {
    fileprivate func updateShopTabVisibility(isLoggedIn: Bool) {
        guard let bar = self.bottomTabBar else { return }
        var items = bar.items ?? []
        if isLoggedIn {
            if !items.contains(where: { $0.title == "Shop" }) {
                let shopItem = UITabBarItem(title: "Shop", image: UIImage(systemName: "cart"), tag: 3)
                items.append(shopItem)
            }
        } else {
            items.removeAll { $0.title == "Shop" }
        }
        bar.items = items
    }
}

// MARK: - Bottom tabs show/hide helpers
extension WebViewController {
    fileprivate func hideBottomTabs() {
        guard let bar = bottomTabBar else { return }
        UIView.animate(withDuration: 0.22) {
            bar.alpha = 0
            bar.isHidden = true
        }
    }

    fileprivate func showBottomTabs() {
        guard let bar = bottomTabBar else { return }
        bar.isHidden = false
        UIView.animate(withDuration: 0.22) {
            bar.alpha = 1
        }
    }
}


