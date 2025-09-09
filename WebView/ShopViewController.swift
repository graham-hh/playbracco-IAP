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

    // Sets up UI for products
    private func setupUI() {
        // Remove all subviews (except navigation bar)
        for subview in view.subviews {
            subview.removeFromSuperview()
        }

        if products.isEmpty {
            // Show "No products found" label
            let label = UILabel()
            label.text = "⚠️ No products found.\nCheck Sandbox login & product IDs."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
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

        // Header label
        let header = UILabel()
        header.text = "Purchase Bracco Coins"
        header.font = UIFont.boldSystemFont(ofSize: 24)
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Stack view for buttons
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        // Add a button for each product
        for product in products {
            let button = UIButton(type: .system)
            button.setTitle("Buy \(product.displayName) – \(product.displayPrice)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            button.layer.cornerRadius = 10
            button.layer.masksToBounds = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.addAction(UIAction { [weak self] _ in
                Task {
                    await IAPManager.shared.purchase(product)
                }
            }, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
