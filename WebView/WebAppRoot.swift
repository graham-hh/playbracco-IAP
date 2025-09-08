import SwiftUI

struct WebAppRoot: View {
    var body: some View {
        WebViewControllerHost()
            .ignoresSafeArea()  // your UIKit controller handles its own insets
    }
}

struct WebViewControllerHost: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        // If you normally instantiate WebViewController with custom init,
        // do that here instead.
        WebViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
