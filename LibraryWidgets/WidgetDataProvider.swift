import Foundation
import SwiftData

@MainActor
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    // Suite name for App Groups
    private let appGroup = "group.com.smartlibrary.shared"
    
    func updateReadingProgress(minutes: Int, goal: Int) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(minutes, forKey: "readingMinutes")
        defaults?.set(goal, forKey: "readingGoal")
    }
    
    func updateNextReservation(title: String, date: Date, lat: Double? = nil, lon: Double? = nil) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(title, forKey: "nextReservationTitle")
        defaults?.set(date.timeIntervalSince1970, forKey: "nextReservationDate")
        if let lat, let lon {
            defaults?.set(lat, forKey: "nextReservationLat")
            defaults?.set(lon, forKey: "nextReservationLon")
        }
    }

    func updatePoints(_ points: Int) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(points, forKey: "rewardPoints")
    }
    
    func updateNextDue(title: String, date: Date, shelf: String? = nil) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(title, forKey: "nextBookTitle")
        defaults?.set(date.timeIntervalSince1970, forKey: "nextDueDate")
        if let shelf {
            defaults?.set(shelf, forKey: "nextBookShelf")
        }
    }

    func updateStreak(_ streak: Int) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(streak, forKey: "readingStreak")
    }
}
