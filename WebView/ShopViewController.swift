import UIKit
import StoreKit

final class ShopViewController: UIViewController {
    // Array to hold fetched products
    private var products: [Product] = []

    // Optional external provider so other code (e.g., the JS bridge) can decide Rookie/Pro
    static var isRookieOverride: (() -> Bool)?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        view.backgroundColor = .systemBackground
        // Load products and build UI based on mode
        if isRookieMode() {
            Task {
                await loadProducts()
            }
        } else {
            setupProUI()
        }
    }

    private func isRookieMode() -> Bool {
        // 0) Allow an external provider to override detection
        if let provider = ShopViewController.isRookieOverride {
            return provider()
        }

        let defaults = UserDefaults.standard

        // 1) Direct boolean flags (preferred, simplest)
        if let flag = defaults.object(forKey: "bracco.isFreePlayMode") as? Bool {
            return flag
        }
        if let flag = defaults.object(forKey: "isFreePlayMode") as? Bool {
            return flag
        }

        // 2) Infer from selectedBalance + balances payload kept in UserDefaults
        if let selected = defaults.object(forKey: "selectedBalance") {
            // If selected balance is the principal "main", then it's Pro (not Rookie)
            if let s = selected as? String, s.lowercased() == "main" {
                return false
            }

            // Prepare candidate numeric IDs
            let selectedIds: [Int] = {
                if let n = selected as? Int { return [n] }
                if let s = selected as? String, let n = Int(s) { return [n] }
                return []
            }()

            // Try a JSON blob saved at balancesJSON
            if let data = defaults.data(forKey: "balancesJSON"),
               let root = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {

                // Two shapes are supported: a dictionary keyed by id, or an array of objects
                if let dictBalances = root["balances"] as? [String: Any] {
                    for id in selectedIds {
                        if let entry = dictBalances["\(id)"] as? [String: Any] {
                            return (entry["isFreePlay"] as? Bool) == true
                        }
                    }
                } else if let arrBalances = root["balances"] as? [[String: Any]] {
                    for id in selectedIds {
                        if let entry = arrBalances.first(where: { ($0["balanceId"] as? Int) == id }) {
                            return (entry["isFreePlay"] as? Bool) == true
                        }
                    }
                }
            }
        }

        // Default to Pro
        return false
    }

    private func setupProUI() {
        // Remove all subviews (except navigation bar)
        for subview in view.subviews {
            subview.removeFromSuperview()
        }

        // Orange background matching rookie theme
        view.backgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0) // Orange

        // Label
        let label = UILabel()
        label.text = "Purchase Bracco Coins"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        // Button
        let button = UIButton(type: .system)
        button.setTitle("Open Shop", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0xF1/255.0, green: 0x56/255.0, blue: 0x22/255.0, alpha: 1.0) // #F15622
        button.layer.cornerRadius = 15
        button.layer.masksToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 32, bottom: 12, right: 32)
        button.addTarget(self, action: #selector(openShopTapped), for: .touchUpInside)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func openShopTapped() {
        if let url = URL(string: "https://cashier.playbracco.com") {
            UIApplication.shared.open(url)
        }
    }

    // Loads products from IAPManager
    private func loadProducts() async {
        // Desired product order
        let desiredOrder = [
            "com.playbracco.coins.2500",
            "com.playbracco.coins.10000",
            "com.playbracco.coins.25000",
            "com.playbracco.coins.50000",
            "com.playbracco.coins.125000",
            "com.playbracco.coins.250000"
        ]
        let fetchedProducts = await IAPManager.shared.products
        self.products = fetchedProducts.sorted {
            guard
                let idx1 = desiredOrder.firstIndex(of: $0.id),
                let idx2 = desiredOrder.firstIndex(of: $1.id)
            else {
                // If not found, preserve original order
                return false
            }
            return idx1 < idx2
        }
        setupUI()
    }

    // Sets up UI for products (custom design)
    private func setupUI() {
        // Remove all subviews (except navigation bar)
        for subview in view.subviews {
            subview.removeFromSuperview()
        }

        // Orange background
        view.backgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0) // Orange

        if products.isEmpty {
            // Show "No products found" label
            let label = UILabel()
            label.text = "⚠️ No products found.\nCheck Sandbox login & product IDs."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .white
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
                label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
            ])
            return
        }

        // --- Custom Header ---
        let headerContainer = UIView()
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerContainer)
        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Title image view
        let titleImageView = UIImageView(image: UIImage(named: "Purchase-Coins-Title"))
        titleImageView.contentMode = .scaleAspectFit
        titleImageView.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleImageView)
        NSLayoutConstraint.activate([
            titleImageView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16),
            titleImageView.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleImageView.heightAnchor.constraint(equalToConstant: 50),
            titleImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        ])

        // Coin header image (bracco_coins_header) - ensure it is visible and constrained below the title image
        let headerImage = UIImageView(image: UIImage(named: "bracco_coins_header"))
        headerImage.contentMode = .scaleAspectFit
        headerImage.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerImage)
        NSLayoutConstraint.activate([
            headerImage.topAnchor.constraint(equalTo: titleImageView.bottomAnchor, constant: 8),
            headerImage.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            headerImage.heightAnchor.constraint(equalToConstant: 120),
            headerImage.widthAnchor.constraint(equalToConstant: 240)
        ])

        // --- ScrollView and Product Cards ---
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16)
        ])

        for product in products {
            // Card container
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 0
            card.layer.borderWidth = 2
            card.layer.borderColor = UIColor.black.cgColor
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 76).isActive = true

            // Horizontal stack for card content
            let cardStack = UIStackView()
            cardStack.axis = .horizontal
            cardStack.alignment = .center
            cardStack.spacing = 16
            cardStack.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(cardStack)
            NSLayoutConstraint.activate([
                cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                cardStack.topAnchor.constraint(equalTo: card.topAnchor),
                cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
            ])

            // Coin icon (left, before product name)
            let coinImage = UIImageView(image: UIImage(named: "bracco_coin_icon"))
            coinImage.contentMode = .scaleAspectFit
            coinImage.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                coinImage.widthAnchor.constraint(equalToConstant: 40),
                coinImage.heightAnchor.constraint(equalToConstant: 40)
            ])
            cardStack.addArrangedSubview(coinImage)

            // Product name label
            let nameLabel = UILabel()
            nameLabel.text = product.displayName
            nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
            nameLabel.textColor = .black
            nameLabel.numberOfLines = 1
            nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            cardStack.addArrangedSubview(nameLabel)

            // Price button (orange pill)
            let priceButton = UIButton(type: .system)
            priceButton.setTitle(product.displayPrice, for: .normal)
            priceButton.titleLabel?.font = UIFont(name: "JetBrainsMono-Bold", size: 18)
            priceButton.setTitleColor(.white, for: .normal)
            priceButton.backgroundColor = UIColor(red: 0xF1/255.0, green: 0x56/255.0, blue: 0x22/255.0, alpha: 1.0) // #F15622
            priceButton.layer.cornerRadius = 15
            priceButton.layer.masksToBounds = true
            priceButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
            priceButton.setContentHuggingPriority(.required, for: .horizontal)
            priceButton.setContentCompressionResistancePriority(.required, for: .horizontal)
            priceButton.addAction(UIAction { [weak self] _ in
                Task {
                    await IAPManager.shared.purchase(product)
                }
            }, for: .touchUpInside)
            cardStack.addArrangedSubview(priceButton)

            stackView.addArrangedSubview(card)
        }
    }

    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
 
