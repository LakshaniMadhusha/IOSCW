import Foundation
import SwiftData

@Observable
final class SignUpViewModel {
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var selectedRole: UserRole = .member
    var errorMessage: String?
    var isSubmitting: Bool = false

    @MainActor
    func submit(auth: AuthService, modelContext: ModelContext) async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        
        await auth.signUp(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password.trimmingCharacters(in: .whitespacesAndNewlines),
            role: selectedRole,
            modelContext: modelContext
        )
        errorMessage = auth.errorMessage
    }
}
