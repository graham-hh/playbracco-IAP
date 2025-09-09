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

// MARK: - Native "Shop" bottom sheet
private final class BraccoShopSheetViewController: UIViewController {

    // Customize these if needed:
    private let externalURL = URL(string: "https://playbracco.com/bracco-coins")!
    private let titleText   = "Purchase Bracco Coins"
    private let bodyText    = "This purchase will open your browser. Coins are used for gameplay."
    private let imageName   = "shop-coins" // Add this to Assets, or change the name

    // MARK: - Style
    struct Style {
        var backgroundColor: UIColor
        var titleFont: UIFont
        var titleColor: UIColor
        var bodyFont: UIFont
        var bodyColor: UIColor
        var ctaBackgroundColor: UIColor
        var ctaTextColor: UIColor

        static func defaultStyle() -> Style {
            let bold = UIFont(name: "JetBrainsMono-Bold", size: 20) ?? .systemFont(ofSize: 20, weight: .bold)
            let regular = UIFont(name: "JetBrainsMono-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .regular)
            return Style(
                backgroundColor: .systemBackground,
                titleFont: bold,
                titleColor: .label,
                bodyFont: regular,
                bodyColor: .secondaryLabel,
                ctaBackgroundColor: UIColor(red: 1.06, green: 0.34, blue: 0.13, alpha: 1.0),
                ctaTextColor: .white
            )
        }
    }
    static var style: Style = Style.defaultStyle()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Self.style.backgroundColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Top spacer for extra padding above the coin artwork
        let topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let img = UIImage(named: imageName)
        let imgView = UIImageView(image: img)
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = false
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.setContentHuggingPriority(.required, for: .vertical)
        imgView.setContentCompressionResistancePriority(.required, for: .vertical)
        // Fixed width to match mock, height derived from image aspect ratio
        imgView.widthAnchor.constraint(equalToConstant: 260).isActive = true // 260pt
        if let img = img, img.size.width > 0 {
            imgView.heightAnchor.constraint(equalTo: imgView.widthAnchor, multiplier: img.size.height / img.size.width).isActive = true
        }

        let title = UILabel()
        title.text = titleText
        title.textAlignment = .center
        title.font = Self.style.titleFont
        title.numberOfLines = 0
        title.textColor = Self.style.titleColor
        title.lineBreakMode = .byWordWrapping
        title.allowsDefaultTighteningForTruncation = true
        title.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)

        let body = UILabel()
        body.text = bodyText
        body.textAlignment = .center
        body.font = Self.style.bodyFont
        body.textColor = Self.style.bodyColor
        body.numberOfLines = 0
        body.lineBreakMode = .byWordWrapping
        body.setContentHuggingPriority(.required, for: .vertical)
        body.setContentCompressionResistancePriority(.required, for: .vertical)

        let cta = UIButton(type: .system)
        // Background matches mock's orange rounded pill
        cta.backgroundColor = Self.style.ctaBackgroundColor
        cta.layer.cornerRadius = 14
        cta.layer.masksToBounds = true
        cta.setTitle(nil, for: .normal)
        cta.tintColor = .white
        cta.adjustsImageWhenHighlighted = false
        cta.accessibilityLabel = "Purchase Bracco Coins"

        // Embed a dedicated image view for exact size control of CTA text artwork
        let ctaImageView = UIImageView(image: UIImage(named: "CTA-text")?.withRenderingMode(.alwaysOriginal))
        ctaImageView.translatesAutoresizingMaskIntoConstraints = false
        ctaImageView.contentMode = .scaleAspectFit
        cta.addSubview(ctaImageView)
        NSLayoutConstraint.activate([
            ctaImageView.centerXAnchor.constraint(equalTo: cta.centerXAnchor),
            ctaImageView.centerYAnchor.constraint(equalTo: cta.centerYAnchor),
            ctaImageView.widthAnchor.constraint(equalToConstant: 226), // 226pt fixed width
            ctaImageView.heightAnchor.constraint(equalTo: ctaImageView.widthAnchor, multiplier: (ctaImageView.image?.size.height ?? 1) / max((ctaImageView.image?.size.width ?? 1), 1))
        ])

        // Button size & insets to match mock: 350x50
        cta.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        cta.widthAnchor.constraint(equalToConstant: 350).isActive = true
        cta.heightAnchor.constraint(equalToConstant: 50).isActive = true

        cta.addTarget(self, action: #selector(openExternal), for: .touchUpInside)

        let close = UIButton(type: .system)
        close.setTitle("Close", for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        stack.addArrangedSubview(topSpacer)
        stack.addArrangedSubview(imgView)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(cta)
        stack.setCustomSpacing(30, after: body)
        // Tighten spacing between coin image → title and title → body
        stack.setCustomSpacing(20, after: imgView)
        stack.setCustomSpacing(6, after: title)

        view.addSubview(stack)
        view.addSubview(close)
        cta.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6),

            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            cta.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -22),
        ])

        if let sheet = presentationController as? UISheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.largestUndimmedDetentIdentifier = nil // always dim to block interaction below
        }
    }

    @objc private func openExternal() {
        UIApplication.shared.open(externalURL, options: [:], completionHandler: nil)
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}

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
    static let height: CGFloat       = 56
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

// Helpers
private func getAssoc(_ obj: AnyObject, _ key: UnsafeRawPointer) -> Any? {
    return objc_getAssociatedObject(obj, key)
}
private func setAssoc(_ obj: AnyObject, _ key: UnsafeRawPointer, _ value: Any?) {
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
    "https://game.playbracco.com/en"
]
private let allowedHost = "game.playbracco.com"
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
extension WebViewController: UITabBarDelegate, WKScriptMessageHandler {
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
            var mode = null;
            var pro = document.querySelector('[data-testid="pro-button"]');
            var rookie = document.querySelector('[data-testid="rookie-button"]');
            if (pro && pro.innerText.toLowerCase().includes("selected")) {
              mode = "pro";
            } else if (rookie && rookie.innerText.toLowerCase().includes("selected")) {
              mode = "rookie";
            }
            if (mode && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mode) {
              window.webkit.messageHandlers.mode.postMessage(mode);
            }
          } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(detectModeJS, completionHandler: nil)

        // Only set up tabs once and only when URL matches rules
        if let done = getAssoc(self, &_hasSetupTabsKey) as? Bool, done { return }
        guard shouldShowTabs(for: webView.url) else { return }
        setupBottomTabs()
        setAssoc(self, &_hasSetupTabsKey, true as Bool?)
    }

    private func setupBottomTabs() {
        print("WVG BottomTabs: setupBottomTabs()")
        // wvg_debugToast("Bottom tabs ready")
        guard let webView = self.webView else { return }

        // Register script message handler for mode switching
        webView.configuration.userContentController.add(self, name: "mode")

        // Apply custom Shop sheet styling
        let custom = BraccoShopSheetViewController.Style(
            backgroundColor: UIColor(red: 87/255.0, green: 22/255.0, blue: 0/255.0, alpha: 1.0), // #571600
            titleFont: UIFont(name: "JetBrainsMono-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold),
            titleColor: .white,
            bodyFont: UIFont(name: "JetBrainsMono-Bold", size: 15) ?? .systemFont(ofSize: 15, weight: .regular),
            bodyColor: UIColor(white: 1, alpha: 0.8),
            ctaBackgroundColor: UIColor(red: 1.06, green: 0.34, blue: 0.13, alpha: 1.0), // brand orange
            ctaTextColor: .white
        )
        setShopSheetStyle(custom)

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
            }
            items.append(item)
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
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bar.heightAnchor.constraint(equalToConstant: BottomTabStyle.height)
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

        // Remove any JS-added bottom padding from earlier runs
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

            // wvg_debugToast("Opening Shop")
            // Rookie mode: present ShopViewController in navigation controller; else present shop sheet
            if UserManager.shared.isRookieMode {
                let shopVC = ShopViewController()
                let nav = UINavigationController(rootViewController: shopVC)
                nav.modalPresentationStyle = .fullScreen
                // Helper to find the top-most presenting controller reliably
                func topMostPresenter(from root: UIViewController?) -> UIViewController? {
                    guard let root = root else { return nil }
                    var top = root
                    // Follow presented chain
                    while let presented = top.presentedViewController {
                        top = presented
                    }
                    // If we ended on a UINavigationController / UITabBarController, use its visible child
                    if let nav = top as? UINavigationController {
                        return topMostPresenter(from: nav.visibleViewController ?? nav.topViewController)
                    }
                    if let tabs = top as? UITabBarController {
                        return topMostPresenter(from: tabs.selectedViewController ?? tabs)
                    }
                    return top
                }
                DispatchQueue.main.async {
                    var root: UIViewController? = self
                    if root?.view.window == nil {
                        // Fallback to the app's key window root if our view is not in a window yet
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let win = scene.windows.first(where: { $0.isKeyWindow }) {
                            root = win.rootViewController
                        } else {
                            root = UIApplication.shared.windows.first?.rootViewController
                        }
                    }
                    guard let presenter = topMostPresenter(from: root) else {
                        print("WVG BottomTabs: presentShopVC() — no presenter found")
                        return
                    }
                    // Avoid double-presenting the ShopViewController
                    if presenter.presentedViewController is UINavigationController {
                        if let navVC = presenter.presentedViewController as? UINavigationController,
                           navVC.viewControllers.first is ShopViewController {
                            print("WVG BottomTabs: ShopViewController already presented")
                            return
                        }
                    }
                    print("WVG BottomTabs: presenting ShopViewController from \(type(of: presenter))")
                    presenter.present(nav, animated: true, completion: nil)
                }
            } else {
                presentShopSheet()
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

    private func presentShopSheet() {
        print("WVG BottomTabs: presentShopSheet()")
        // wvg_debugToast("Opening Shop")

        let sheetVC = BraccoShopSheetViewController()

        // Configure preferred presentation styles
        if #available(iOS 16.0, *) {
            sheetVC.modalPresentationStyle = .pageSheet
            if let spc = sheetVC.presentationController as? UISheetPresentationController {
                let small = UISheetPresentationController.Detent.custom(identifier: .init("braccoSmall")) { _ in
                    return 384 // fixed height in points for the sheet card
                }
                spc.detents = [small]
                spc.selectedDetentIdentifier = small.identifier
                spc.prefersScrollingExpandsWhenScrolledToEdge = false
                spc.prefersGrabberVisible = true
                spc.largestUndimmedDetentIdentifier = nil // dim background; block interactions below
            }
        } else if #available(iOS 15.0, *) {
            sheetVC.modalPresentationStyle = .pageSheet
            if let spc = sheetVC.presentationController as? UISheetPresentationController {
                spc.detents = [.medium()]
                spc.selectedDetentIdentifier = .medium
                spc.prefersGrabberVisible = true
                spc.largestUndimmedDetentIdentifier = nil // dim background; block interactions below
            }
        } else {
            // Fallback for iOS < 15
            if UIDevice.current.userInterfaceIdiom == .pad {
                sheetVC.modalPresentationStyle = .formSheet
                sheetVC.preferredContentSize = CGSize(width: 520, height: 480)
            } else {
                sheetVC.modalPresentationStyle = .overFullScreen
                sheetVC.view.backgroundColor = BraccoShopSheetViewController.style.backgroundColor.withAlphaComponent(0.98)
            }
        }

        // Helper to find the top-most presenting controller reliably
        func topMostPresenter(from root: UIViewController?) -> UIViewController? {
            guard let root = root else { return nil }
            var top = root
            // Follow presented chain
            while let presented = top.presentedViewController {
                top = presented
            }
            // If we ended on a UINavigationController / UITabBarController, use its visible child
            if let nav = top as? UINavigationController {
                return topMostPresenter(from: nav.visibleViewController ?? nav.topViewController)
            }
            if let tabs = top as? UITabBarController {
                return topMostPresenter(from: tabs.selectedViewController ?? tabs)
            }
            return top
        }

        DispatchQueue.main.async {
            // Prefer presenting from `self`'s hierarchy if possible
            var root: UIViewController? = self
            if root?.view.window == nil {
                // Fallback to the app's key window root if our view is not in a window yet
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let win = scene.windows.first(where: { $0.isKeyWindow }) {
                    root = win.rootViewController
                } else {
                    root = UIApplication.shared.windows.first?.rootViewController
                }
            }

            guard let presenter = topMostPresenter(from: root) else {
                print("WVG BottomTabs: presentShopSheet() — no presenter found")
                return
            }

            // Avoid double-presenting the sheet
            if presenter.presentedViewController is BraccoShopSheetViewController {
                print("WVG BottomTabs: Shop sheet already presented")
                return
            }

            print("WVG BottomTabs: presenting from \(type(of: presenter))")
            presenter.present(sheetVC, animated: true, completion: nil)
        }
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
        bar.isTranslucent = BottomTabStyle.isTranslucent
        bar.tintColor = BottomTabStyle.selectedColor
        bar.unselectedItemTintColor = BottomTabStyle.unselectedColor
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            BottomTabStyle.isTranslucent ? appearance.configureWithDefaultBackground()
                                         : appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = BottomTabStyle.backgroundColor
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
            bar.standardAppearance = appearance
            if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = appearance }
        } else {
            bar.barTintColor = BottomTabStyle.backgroundColor
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

// MARK: - Shop Sheet Style API
extension WebViewController {
    /// Set global style for the Shop bottom sheet.
    fileprivate func setShopSheetStyle(_ style: BraccoShopSheetViewController.Style) {
        BraccoShopSheetViewController.style = style
    }
}



    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "mode" {
            // JS sent us "rookie" or "pro"
            if let modeStr = message.body as? String {
                UserManager.shared.isRookieMode = (modeStr == "rookie")
                // Debug print statements
                if UserManager.shared.isRookieMode {
                    print("WVG BottomTabs: Rookie mode detected (from JS)")
                } else {
                    print("WVG BottomTabs: Pro mode detected (from JS)")
                }
            }
        }
    }
