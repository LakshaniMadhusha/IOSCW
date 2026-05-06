import Foundation
import SwiftData

@MainActor
class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    // Suite name for App Groups
    private let appGroup = "group.com.smartlibrary.shared"
    
    func updateStreak(_ streak: Int) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(streak, forKey: "readingStreak")
    }
    
    func updateNextDue(title: String, date: Date) {
        let defaults = UserDefaults(suiteName: appGroup)
        defaults?.set(title, forKey: "nextBookTitle")
        defaults?.set(date.timeIntervalSince1970, forKey: "nextDueDate")
    }
}
