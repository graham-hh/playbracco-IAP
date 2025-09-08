import LocalAuthentication

enum BiometricAuth {
    static func authenticate(
        reason: String = "Authenticate to continue",
        allowDevicePasscodeFallback: Bool = true,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var error: NSError?
        let policy: LAPolicy = allowDevicePasscodeFallback
            ? .deviceOwnerAuthentication          // biometrics + passcode fallback
            : .deviceOwnerAuthenticationWithBiometrics // biometrics only

        guard context.canEvaluatePolicy(policy, error: &error) else {
            completion(false, error) // e.g. no biometrics enrolled
            return
        }

        // Optional: you can tailor the reason based on biometry type
        let reasonText: String
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID: reasonText = "Use Face ID to unlock"
            case .touchID: reasonText = "Use Touch ID to unlock"
            default: reasonText = reason
            }
        } else {
            reasonText = reason
        }

        context.evaluatePolicy(policy, localizedReason: reasonText) { success, evalError in
            DispatchQueue.main.async {
                completion(success, evalError)
            }
        }
    }
}
