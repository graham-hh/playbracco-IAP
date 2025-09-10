import UIKit
import StoreKit

final class ShopViewController: UIViewController {
    // Array to hold fetched products
    private var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bracco Shop"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        view.backgroundColor = .systemBackground
        // Load products and build UI
        Task {
            await loadProducts()
        }
    }

    // Loads products from IAPManager
    private func loadProducts() async {
        self.products = await IAPManager.shared.products
        setupUI()
    }

    // Sets up UI for products (custom design)
    private func setupUI() {
        // Remove all subviews (except navigation bar)
        for subview in view.subviews {
            subview.removeFromSuperview()
        }

        // Orange background
        view.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0) // Orange

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
            headerContainer.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Close button (X)
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        headerContainer.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Title label
        let titleLabel = UILabel()
        titleLabel.text = "PURCHASE BRACCO COINS"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 16)
        ])

        // Coin header image
        let headerImage = UIImageView(image: UIImage(named: "bracco_coins_header"))
        headerImage.contentMode = .scaleAspectFit
        headerImage.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(headerImage)
        NSLayoutConstraint.activate([
            headerImage.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            headerImage.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            headerImage.heightAnchor.constraint(equalToConstant: 36),
            headerImage.widthAnchor.constraint(equalToConstant: 80)
        ])

        // --- ScrollView and Product Cards ---
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 8),
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
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16)
        ])

        for product in products {
            // Card container
            let card = UIView()
            card.backgroundColor = .white
            card.layer.cornerRadius = 20
            card.layer.borderWidth = 2
            card.layer.borderColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0).cgColor // Orange border
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

            // Coin icon
            let coinImage = UIImageView(image: UIImage(named: "bracco_coin_icon"))
            coinImage.contentMode = .scaleAspectFit
            coinImage.translatesAutoresizingMaskIntoConstraints = false
            coinImage.widthAnchor.constraint(equalToConstant: 40).isActive = true
            coinImage.heightAnchor.constraint(equalToConstant: 40).isActive = true
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
            priceButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            priceButton.setTitleColor(.white, for: .normal)
            priceButton.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0)
            priceButton.layer.cornerRadius = 18
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
