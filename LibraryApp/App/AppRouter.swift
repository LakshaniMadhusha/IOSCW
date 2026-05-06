import SwiftUI
import SwiftData

struct AppRouter: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showSplash: Bool = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .environmentObject(auth)
                    .task {
                        auth.bootstrap(modelContext: modelContext)
                        // Request notification permission
                        _ = await NotificationService.shared.requestPermission()
                        // Give the splash screen animation time to play out
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                    }
            } else {
                switch auth.state {
                case .signedOut:
                    AuthEntryView()
                        .environmentObject(auth)
                        .transition(.opacity)
                case .signedIn(let user):
                    Group {
                        if auth.isAppLocked {
                            AppLockView()
                        } else {
                            if user.role == .member {
                                MemberTabView(user: user)
                            } else {
                                LibrarianTabView(user: user)
                            }
                        }
                    }
                    .environmentObject(auth)
                }
            }
        }
        .background(Color.pageBg.ignoresSafeArea())
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                auth.didEnterBackground()
            case .active:
                auth.willEnterForeground()
            default:
                break
            }
        }
    }
}

