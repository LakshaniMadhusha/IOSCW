import SwiftUI

struct BiometricReservationConfirmationView: View {
    enum ViewState {
        case idle
        case authenticating
        case failed(String)
        case success
    }

    @Environment(\.dismiss) private var dismiss

    let seatLabel: String
    let onConfirmAuthenticated: @MainActor () -> Void

    @State private var state: ViewState = .idle
    private let biometric = BiometricAuthService()

    var body: some View {
        VStack(spacing: 12) {
            Text("Confirm Reservation")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Reserve seat \(seatLabel) using Face ID / Touch ID or passcode.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if case .failed(let msg) = state {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.coral)
            }

            Button {
                Task { await authenticateAndConfirm() }
            } label: {
                if case .authenticating = state {
                    ProgressView().tint(.white)
                } else {
                    Text("Confirm")
                }
            }
            .buttonStyle(.primaryButton)

            Button("Cancel") { dismiss() }
                .foregroundColor(.textPrimary)
                .buttonStyle(.plain)
        }
        .padding(20)
        .presentationDetents([.medium])
    }

    private func authenticateAndConfirm() async {
        await MainActor.run { state = .authenticating }
        do {
            try await biometric.authenticate(reason: "Confirm seat reservation")
            await MainActor.run {
                onConfirmAuthenticated()
                state = .success
                dismiss()
            }
        } catch {
            await MainActor.run {
                state = .failed(error.localizedDescription)
            }
        }
    }
}

