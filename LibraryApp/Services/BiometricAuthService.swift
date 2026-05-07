import Foundation
import LocalAuthentication

struct BiometricAuthService {
    enum BiometricError: LocalizedError {
        case notAvailable
        case failed
        case notEnrolled
        case simulatorHint

        var errorDescription: String? {
            switch self {
            case .notAvailable: 
                return "Face ID / Touch ID is not supported on this device."
            case .failed: 
                return "Authentication failed. Please try again."
            case .notEnrolled:
                return "No biometric profiles found. Please set up Face ID in iOS Settings."
            case .simulatorHint:
                return "Simulator: Please go to 'Features > Face ID > Enrolled' in the menu."
            }
        }
    }

    /// Uses Face ID / Touch ID 
    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedFallbackTitle = "" // Hide passcode fallback

        var error: NSError?
        
        #if targetEnvironment(simulator)
        // Check if biometric is enrolled in simulator
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            throw BiometricError.simulatorHint
        }
        #else
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError, laError.code == .biometryNotEnrolled {
                throw BiometricError.notEnrolled
            }
            throw BiometricError.notAvailable
        }
        #endif

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            if !success { throw BiometricError.failed }
        } catch {
            throw BiometricError.failed
        }
    }
}
