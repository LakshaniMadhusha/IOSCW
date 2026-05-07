import Foundation
import SwiftData

@Observable
final class SignInViewModel {
    var email: String = "sarah@library.com"
    var password: String = "password123"
    var selectedRole: UserRole = .member
    var errorMessage: String?
    var isSubmitting: Bool = false

    @MainActor
    func submit(auth: AuthService, modelContext: ModelContext) async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        await auth.signIn(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password.trimmingCharacters(in: .whitespacesAndNewlines),
            role: selectedRole, 
            modelContext: modelContext
        )
        errorMessage = auth.errorMessage
    }

    @MainActor
    func biometricLogin(auth: AuthService, modelContext: ModelContext) async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            let biometric = BiometricAuthService()
            try await biometric.authenticate(reason: "Sign in to Library Companion")
            
            // On success, try to find the last logged in user who has biometrics enabled
            let savedUserIdString = UserDefaults.standard.string(forKey: "loggedInUserIdKey")
            if let userIdString = savedUserIdString, let userId = UUID(uuidString: userIdString) {
                let predicate = #Predicate<AppUser> { $0.id == userId }
                let descriptor = FetchDescriptor<AppUser>(predicate: predicate)
                if let user = try modelContext.fetch(descriptor).first, user.isBiometricEnabled {
                    auth.signIn(user: user)
                    return
                }
            }
            errorMessage = "Please sign in with password first to enable Biometrics."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
