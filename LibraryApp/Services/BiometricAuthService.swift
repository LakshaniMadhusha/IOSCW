import Foundation
import LocalAuthentication

struct BiometricAuthService {
    enum BiometricError: LocalizedError {
        case notAvailable
        case failed

        var errorDescription: String? {
            switch self {
            case .notAvailable: return "Device authentication is not available."
            case .failed: return "Authentication failed."
            }
        }
    }

    /// Uses Face ID / Touch ID when available, and falls back to device passcode.
    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw BiometricError.notAvailable
        }

        let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        guard success else { throw BiometricError.failed }
    }
}

