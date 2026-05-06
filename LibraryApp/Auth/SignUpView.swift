import SwiftUI
import SwiftData

struct SignUpView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.modelContext) private var modelContext

    @State private var vm = SignUpViewModel()
    @FocusState private var focusedField: Field?
    var onGoToSignIn: () -> Void

    enum Field {
        case name, email, password
    }

    var body: some View {
        VStack(spacing: 32) {
            // Header Graphic
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundStyle(
                        LinearGradient(colors: [.accent, .accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(color: .accent.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Join us to get started")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.top, 10)

            // Role Segmented Control
            Picker("Role", selection: $vm.selectedRole) {
                Text("Member").tag(UserRole.member)
                Text("Librarian").tag(UserRole.librarian)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            
            // Input Fields
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(focusedField == .name ? .accent : .textSecondary)
                        .frame(width: 24)
                    TextField("Full Name", text: $vm.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                }
                .padding()
                .background(Color.surfaceBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(focusedField == .name ? Color.accent : Color.clear, lineWidth: 1.5)
                )

                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(focusedField == .email ? .accent : .textSecondary)
                        .frame(width: 24)
                    TextField("Email Address", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                }
                .padding()
                .background(Color.surfaceBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(focusedField == .email ? Color.accent : Color.clear, lineWidth: 1.5)
                )

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(focusedField == .password ? .accent : .textSecondary)
                        .frame(width: 24)
                    SecureField("Password", text: $vm.password)
                        .focused($focusedField, equals: .password)
                }
                .padding()
                .background(Color.surfaceBg)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(focusedField == .password ? Color.accent : Color.clear, lineWidth: 1.5)
                )
            }
            .padding(.horizontal, 20)

            VStack(spacing: 20) {
                if let msg = auth.errorMessage ?? vm.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(msg)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                }

                Button {
                    focusedField = nil
                    Task { await vm.submit(auth: auth, modelContext: modelContext) }
                } label: {
                    HStack {
                        if auth.isLoading || vm.isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text("Register")
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.accent, .accent.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .buttonStyle(.plain)

                Button(action: onGoToSignIn) {
                    Group {
                        Text("Already have an account? ")
                            .foregroundColor(.textSecondary)
                        + Text("Sign In")
                            .foregroundColor(.accent)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 10)
            }
        }
        .padding(.vertical, 24)
        .background(Color.cardBg)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.06), radius: 25, x: 0, y: 12)
        .padding(.horizontal, 16)
    }
}
