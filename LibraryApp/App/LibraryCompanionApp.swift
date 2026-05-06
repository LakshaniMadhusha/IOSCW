import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct LibraryCompanionApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            Book.self,
            Loan.self,
            Reservation.self,
            Hall.self,
            Seat.self,
            ReadingSession.self,
            Badge.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            do {
                let config = ModelConfiguration()
                let storeURL = config.url
                if FileManager.default.fileExists(atPath: storeURL.path) {
                    try FileManager.default.removeItem(at: storeURL)
                }
                return try ModelContainer(for: Schema([
                    AppUser.self,
                    Book.self,
                    Loan.self,
                    Reservation.self,
                    Hall.self,
                    Seat.self,
                    ReadingSession.self,
                    Badge.self,
                ]))
            } catch {
                fatalError("SwiftData container init failed even after deleting store: \(error)")
            }
        }
    }()

    @State private var authService = AuthService()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authService)
                .task {
                    // Activate Global Dual Offline-Cloud Synchronization Daemon
                    FirebaseSyncService.shared.startSyncing(container: container)
                }
        }
        .modelContainer(container)
    }
}
