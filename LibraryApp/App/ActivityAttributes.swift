import Foundation
import ActivityKit

struct LibraryActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var message: String
        var progress: Double // 0.0 to 1.0
        var endTime: Date?
    }
    
    var title: String
    var activityType: String // "pickup", "booking", "dueReminder"
}
