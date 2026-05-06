import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    // 1. Pickup Activity
    func startPickupActivity(bookTitle: String, branch: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = LibraryActivityAttributes(title: "Ready for Pickup", activityType: "pickup")
        let initialState = LibraryActivityAttributes.ContentState(
            status: "Ready",
            message: "\(bookTitle) at \(branch)",
            progress: 1.0,
            endTime: Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        )
        
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: initialState, staleDate: nil))
            print("Successfully started pickup activity")
        } catch {
            print("Error starting pickup activity: \(error.localizedDescription)")
        }
    }
    
    // 2. Booking Activity
    func startBookingActivity(hallName: String, durationHours: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let endTime = Date().addingTimeInterval(TimeInterval(durationHours * 3600))
        let attributes = LibraryActivityAttributes(title: "Active Booking", activityType: "booking")
        let initialState = LibraryActivityAttributes.ContentState(
            status: "In Progress",
            message: "Room: \(hallName)",
            progress: 0.1,
            endTime: endTime
        )
        
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: initialState, staleDate: nil))
        } catch {
            print("Error starting booking activity: \(error.localizedDescription)")
        }
    }
    
    // 3. Due Reminder Activity
    func startDueReminderActivity(bookTitle: String, dueAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = LibraryActivityAttributes(title: "Book Due Soon", activityType: "dueReminder")
        let initialState = LibraryActivityAttributes.ContentState(
            status: "Urgent",
            message: "Return \(bookTitle)",
            progress: 0.9,
            endTime: dueAt
        )
        
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: initialState, staleDate: nil))
        } catch {
            print("Error starting due reminder activity: \(error.localizedDescription)")
        }
    }
    
    // 4. Reading Challenge Activity
    func startReadingChallengeActivity(bookTitle: String, durationMinutes: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let endTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        let attributes = LibraryActivityAttributes(title: "Reading Challenge", activityType: "challenge")
        let initialState = LibraryActivityAttributes.ContentState(
            status: "Sprint!",
            message: "Reading: \(bookTitle)",
            progress: 0.0,
            endTime: endTime
        )
        
        do {
            _ = try Activity.request(attributes: attributes, content: .init(state: initialState, staleDate: nil))
        } catch {
            print("Error starting challenge activity: \(error.localizedDescription)")
        }
    }
    
    // End all activities
    func endAllActivities() {
        Task {
            for activity in Activity<LibraryActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
}
