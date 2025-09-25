import UIKit
import SafariServices

class ProShopViewController: UIViewController {
    private let externalURL: URL
    private let titleText: String
    private let bodyText: String
    private let imageName: String

    // UI elements
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    // Initializer
    init(externalURL: URL,
         titleText: String = "Purchase Bracco Coins",
         bodyText: String = "This purchase will open your browser. Coins are used for gameplay.",
         imageName: String = "shop-coins")
    {
        self.externalURL = externalURL
        self.titleText = titleText
        self.bodyText = bodyText
        self.imageName = imageName
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported, use init(externalURL:…) instead")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 241/255, green: 86/255, blue: 34/255, alpha: 1.0) // Bracco orange
        setupViews()
    }

    private func setupViews() {
        // image
        if let img = UIImage(named: imageName) {
            imageView.image = img
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        // title
        titleLabel.text = titleText.uppercased()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // body
        bodyLabel.text = bodyText
        bodyLabel.font = UIFont.systemFont(ofSize: 16)
        bodyLabel.textColor = .white
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bodyLabel)

        // open button
        openButton.setTitle("GO TO PURCHASE PAGE", for: .normal)
        openButton.setTitleColor(.white, for: .normal)
        openButton.backgroundColor = UIColor(red: 87/255, green: 22/255, blue: 0/255, alpha: 1.0) // dark brown
        openButton.layer.cornerRadius = 8
        openButton.clipsToBounds = true
        openButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        openButton.addTarget(self, action: #selector(didTapOpen), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openButton)

        // close button
        closeButton.setTitle("Cancel", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            openButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            openButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            openButton.heightAnchor.constraint(equalToConstant: 50),

            closeButton.topAnchor.constraint(equalTo: openButton.bottomAnchor, constant: 16),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func didTapOpen() {
        // open in Safari (or SFSafariViewController if you prefer)
        UIApplication.shared.open(externalURL, options: [:], completionHandler: nil)
        dismiss(animated: true, completion: nil)
    }

    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
}
