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
}
