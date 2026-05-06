//
//  LibraryApp.swift
//  Library
//
//  Created by COBSCCOMP242P-062 on 2026-04-20.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct LibraryApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    let container: ModelContainer = {
        let schema = Schema([
            AppUser.self,
            Book.self,
            Loan.self,
            Reservation.self,
            Hall.self,
            HallEvent.self,
            Seat.self,
            HallReservation.self,
            ReadingSession.self,
            Badge.self,
            AppNotification.self,
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
                    HallEvent.self,
                    Seat.self,
                    HallReservation.self,
                    ReadingSession.self,
                    Badge.self,
                    AppNotification.self,
                ]))
            } catch {
                fatalError("SwiftData container init failed even after deleting store: \(error)")
            }
        }
    }()

    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authService)
                .modelContainer(container)
                .task {
                    // Request notification permission
                    _ = await NotificationService.shared.requestPermission()
                    
                    // Delay sync slightly to prioritize initial UI rendering and avoid Watchdog timeouts
                    try? await Task.sleep(for: .seconds(1.0))
                    
                    // Activate Global Dual Offline-Cloud Synchronization Daemon
                    FirebaseSyncService.shared.startSyncing(container: container)
                }
        }
    }
}
