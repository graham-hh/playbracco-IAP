import UIKit

final class ShopViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bracco Shop"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeTapped))
        view.backgroundColor = .systemBackground
        // Add your shop UI here
    }

    @objc private func closeTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
