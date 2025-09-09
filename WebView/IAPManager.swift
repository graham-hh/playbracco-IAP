import StoreKit

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    @Published var products: [Product] = []
    @Published var purchasedIDs = Set<String>()
    
    // Your App Store product IDs
    private let productIDs: [String] = [
        "com.playbracco.coins.100"
    ]
    
    init() {
        Task {
            await fetchProducts()
            await updatePurchasedProducts()
        }
    }
    
    // Load products from App Store
    func fetchProducts() async {
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }
    
    // Purchase product
    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // ✅ Successful purchase
                    purchasedIDs.insert(transaction.productID)
                    
                    // Get receipt for backend
                    if let receiptURL = Bundle.main.appStoreReceiptURL,
                       let receiptData = try? Data(contentsOf: receiptURL) {
                        let receiptString = receiptData.base64EncodedString()
                        // Send to your server here
                        print("Receipt: \(receiptString)")
                    }
                    
                    await transaction.finish()
                case .unverified(_, let error):
                    print("Unverified transaction: \(error)")
                }
            case .userCancelled:
                print("Purchase cancelled")
            case .pending:
                print("Purchase pending")
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    // Restore purchases (optional for consumables, mandatory for non-consumables)
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedIDs.insert(transaction.productID)
            }
        }
    }
}
