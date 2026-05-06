import SwiftUI

struct AppLockView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("App Locked")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("Unlock with Face ID / Touch ID or passcode.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            if let msg = auth.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.coral)
            }

            Button {
                Task { await auth.unlockApp() }
            } label: {
                if auth.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Unlock")
                }
            }
            .buttonStyle(.primaryButton)
            .frame(maxWidth: 320)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pageBg.ignoresSafeArea())
    }
}

