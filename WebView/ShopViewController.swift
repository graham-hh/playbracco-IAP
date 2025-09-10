import UIKit
import StoreKit

final class ShopViewController: UIViewController {
    // Array to hold fetched products
    private var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Removed close button for navigation; controller can now be pushed or in a tab bar
        view.backgroundColor = .systemBackground
        // Load products and build UI
        Task {
            await loadProducts()
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
        view.backgroundColor = UIColor(red: 1.06, green: 0.34, blue: 0.13, alpha: 1.0) // Orange

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

}
 
