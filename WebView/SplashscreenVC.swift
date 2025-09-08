//  SplashscreenVC.swift
//  WebViewGold
//
//  Face ID / Touch ID integrated launch screen
//

import UIKit
import SwiftyGif
import LocalAuthentication

class SplashscreenVC: UIViewController {

    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet var mainbackview: UIView!
    @IBOutlet weak var loadingSign: UIActivityIndicatorView!
    @IBOutlet weak var splashWidthRatio: NSLayoutConstraint!
    @IBOutlet weak var autheticateBtn: UIButton!

    var gameTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        if splashScreenEnabled {
            loadingSign.isHidden = true
            view.backgroundColor = Constants.splashscreencolor

            if scaleSplashImage == 100 {
                splashWidthRatio.isActive = false
                imageview.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageview.topAnchor.constraint(equalTo: view.topAnchor),
                    imageview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    imageview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    imageview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                ])
                imageview.contentMode = .scaleAspectFill
            }

            do {
                let gif = try UIImage(gifName: "splash", levelOfIntegrity: 1)
                let gifManager = SwiftyGifManager(memoryLimit: 100)
                imageview.setGifImage(gif, manager: gifManager, loopCount: 1)
                imageview.delegate = self
            } catch {
                print("GIF load error:", error)
            }
        } else {
            loadingSign.isHidden = true
        }

        if !splashScreenEnabled {
            gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: false)
        }

        if scaleSplashImage != 100 {
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            splashWidthRatio.constant = screenWidth <= screenHeight
                ? screenWidth * (CGFloat(scaleSplashImage) / 100.0)
                : screenHeight * (CGFloat(scaleSplashImage) / 100.0)
        }

        autheticateBtn.isHidden = true
        autheticateBtn.addTarget(self, action: #selector(authBtnTapped), for: .touchUpInside)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // One-time skip for biometrics (set after onboarding completes)
        if UserDefaults.standard.bool(forKey: "wvg.skipBioOnce") {
            UserDefaults.standard.set(false, forKey: "wvg.skipBioOnce") // consume it
            // Proceed directly without auth once
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.fireTimer()
            }
            return
        }

        if enableBioMetricAuth {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.authenticateUser()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.fireTimer()
            }
        }
    }

    @objc func fireTimer() {
        print("Timer fired!")
        if #available(iOS 13.0, *) {
            if let ncv = storyboard?.instantiateViewController(identifier: "homenavigation") as? UINavigationController {
                present(ncv, animated: false, completion: nil)
            }
        } else {
            if let ncv = storyboard?.instantiateViewController(withIdentifier: "homenavigation") as? UINavigationController {
                present(ncv, animated: false, completion: nil)
            }
        }
    }

    func authenticateUser() {
        let context = LAContext()
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            print("Biometrics unavailable:", authError?.localizedDescription ?? "N/A")
            fireTimer()
            return
        }

        let reason = "Unlock to continue."

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.fireTimer()
                } else {
                    self.autheticateBtn.isHidden = false
                    if let error = error {
                        print("Biometric auth failed:", error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc func authBtnTapped() {
        autheticateBtn.isHidden = true
        if !UserDefaults.standard.bool(forKey: "kDidSeeOnboarding") {
            if let onboardingVC = storyboard?.instantiateViewController(withIdentifier: "OnboardingView") {
                onboardingVC.modalPresentationStyle = .fullScreen
                present(onboardingVC, animated: true, completion: nil)
            }
        } else {
            authenticateUser()
        }
    }
}

extension SplashscreenVC: SwiftyGifDelegate {
    func gifURLDidFinish(sender: UIImageView) { }
    func gifURLDidFail(sender: UIImageView) { }
    func gifDidStart(sender: UIImageView) { }
    func gifDidLoop(sender: UIImageView) { }
    func gifDidStop(sender: UIImageView) { }
}
