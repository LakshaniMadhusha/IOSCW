import Foundation
import UserNotifications
import SwiftData

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    func scheduleDueDateReminder(for loan: Loan, modelContext: ModelContext? = nil, daysBefore: Int = 1) {
        guard let dueDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: loan.dueAt) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Book Due Soon"
        content.body = "\"\(loan.book?.title ?? "Your book")\" is due in \(daysBefore) day(s)."
        content.sound = .default
        content.categoryIdentifier = "DUE_REMINDER"

        if let context = modelContext, let user = loan.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reminder", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "due-\(loan.id.uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling due reminder: \(error)")
            }
        }
    }

    func schedulePickupAlert(for reservation: Reservation, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Book Ready for Pickup"
        content.body = "\"\(reservation.book?.title ?? "Your reserved book")\" is now available for pickup."
        content.sound = .default
        content.categoryIdentifier = "PICKUP_ALERT"

        if let context = modelContext, let user = reservation.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "pickup", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }

        // Schedule immediately for demo; in real app, schedule when status changes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "pickup-\(reservation.id.uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling pickup alert: \(error)")
            }
        }
    }

    func scheduleSeatConfirmation(for reservation: Reservation, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Seat Reservation Confirmed"
        content.body = "Your seat reservation has been confirmed. Enjoy your study session!"
        content.sound = .default
        content.categoryIdentifier = "SEAT_CONFIRMATION"

        if let context = modelContext, let user = reservation.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "seat-\(reservation.id.uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling seat confirmation: \(error)")
            }
        }
    }

    func scheduleChallengeMilestone(userId: UUID, milestone: String, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Reading Challenge Milestone!"
        content.body = "Congratulations! You've reached: \(milestone)"
        content.sound = .default
        content.categoryIdentifier = "CHALLENGE_MILESTONE"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "challenge", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "challenge-\(userId.uuidString)-\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling challenge milestone: \(error)")
            }
        }
    }

    func scheduleLibrarianAnnouncement(title: String, message: String, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "LIBRARIAN_ANNOUNCEMENT"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "announcement", userId: nil)
            context.insert(appNotif)
            try? context.save()
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "announcement-\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling announcement: \(error)")
            }
        }
    }

    func scheduleHallBookingConfirmation(hallName: String, hallAddress: String, detailsDescription: String, userId: UUID, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Hall Booking Confirmed"
        content.body = "Your booking at \(hallName) (\(hallAddress)) is confirmed. \(detailsDescription)"
        content.sound = .default
        content.categoryIdentifier = "HALL_BOOKING_CONFIRMATION"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "hall-booking-\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling hall booking confirmation: \(error)")
            }
        }
    }

    func scheduleBookReservationConfirmation(for bookTitle: String, userId: UUID, modelContext: ModelContext? = nil) {
        let content = UNMutableNotificationContent()
        content.title = "Book Reserved"
        content.body = "Your reservation for \"\(bookTitle)\" is confirmed. It will appear in your Upcoming list."
        content.sound = .default
        content.categoryIdentifier = "BOOK_RESERVATION_CONFIRMATION"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: "book-reservation-\(UUID().uuidString)", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Error scheduling book reservation confirmation: \(error)")
            }
        }
    }

    func cancelNotification(for identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification as a banner and play sound even if the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
}