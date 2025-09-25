import Foundation

class UserManager {
    static let shared = UserManager()
    
    private init() { }
    
    // Default to Rookie mode for now
    var isRookieMode: Bool = true {
        didSet {
            print("🎮 Mode updated in UserManager: \(isRookieMode ? "Rookie" : "Pro")")
        }
    }
}
