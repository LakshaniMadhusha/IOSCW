import SwiftUI

struct AuthEntryView: View {
    @EnvironmentObject var auth: AuthService
    @State private var showSignUp = false

    var body: some View {
        VStack(spacing: 12) {
            if showSignUp {
                SignUpView(onGoToSignIn: { showSignUp = false })
            } else {
                SignInView(onGoToSignUp: { showSignUp = true })
            }
        }
        .padding(.bottom, 18)
    }
}

