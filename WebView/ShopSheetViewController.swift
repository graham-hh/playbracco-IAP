import UIKit

final class ShopSheetViewController: UIViewController {

    // Customize these
    private let externalURL = URL(string: "https://playbracco.com")! // ← your purchase URL
    private let titleText   = "Buy Bracco Coins"
    private let bodyText    = "Top up your balance to play more. Purchases open in your browser."

    private let imageName   = "shop-coins" // add a PNG to Assets (e.g. 512x256)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Layout
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Image
        let imgView = UIImageView(image: UIImage(named: imageName))
        imgView.contentMode = .scaleAspectFit
        imgView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        imgView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        // Title
        let title = UILabel()
        title.text = titleText
        title.textAlignment = .center
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.numberOfLines = 0

        // Body
        let body = UILabel()
        body.text = bodyText
        body.textAlignment = .center
        body.font = .systemFont(ofSize: 16, weight: .regular)
        body.textColor = .secondaryLabel
        body.numberOfLines = 0

        // CTA button
        let cta = UIButton(type: .system)
        cta.setTitle("Go to Checkout", for: .normal)
        cta.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cta.backgroundColor = UIColor(red: 1.06, green: 0.34, blue: 0.13, alpha: 1.0) // your orange
        cta.tintColor = .white
        cta.layer.cornerRadius = 12
        cta.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        cta.addTarget(self, action: #selector(openExternal), for: .touchUpInside)

        // Close button
        let close = UIButton(type: .system)
        close.setTitle("Close", for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        // Stack content
        stack.addArrangedSubview(imgView)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(cta)

        view.addSubview(stack)
        view.addSubview(close)

        // Constraints
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])

        // Sheet style (iOS 15+)
        if let sheet = presentationController as? UISheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.largestUndimmedDetentIdentifier = .medium
        }
    }

    @objc private func openExternal() {
        UIApplication.shared.open(externalURL, options: [:], completionHandler: nil)
    }

    @objc private func closeTapped() {
        dismiss(animated: true, completion: nil)
    }
}
