import Foundation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Properties

    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var featuredBooks: [Book] = []
    private(set) var activeLoans: [Loan] = []
    private(set) var activeReservations: [Reservation] = []
    private(set) var upcomingHallReservations: [HallReservation] = []
    private(set) var upcomingBookReservations: [Reservation] = []
    private(set) var readingStreak: Int = 0
    private(set) var rewardPoints: Int = 0

    // MARK: - Load

    func load(user: AppUser, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await Task.sleep(for: .milliseconds(150))

            let userId = user.id

            // ✅ Featured books — no predicate needed
            featuredBooks = try modelContext
                .fetch(FetchDescriptor<Book>())
                .shuffled()
                .prefix(4)
                .map { $0 }

            // ✅ Active loans — fetch all, filter in memory
            // #Predicate cannot traverse optional relationships (loan.user?.id)
            // so we fetch all loans and filter by userId in Swift
            let allLoans = try modelContext.fetch(FetchDescriptor<Loan>())
            activeLoans = allLoans.filter {
                $0.returnedAt == nil && $0.user?.id == userId
            }

            // Schedule due date reminders for active loans
            for loan in activeLoans {
                NotificationService.shared.scheduleDueDateReminder(for: loan, modelContext: modelContext)
            }

            // ✅ Approved reservations — same pattern
            // ReservationStatus is a Codable enum stored as String rawValue
            // SwiftData can predicate on rawValue strings but NOT on
            // optional relationship keypaths, so filter in memory
            let allReservations = try modelContext.fetch(FetchDescriptor<Reservation>())
            activeReservations = allReservations.filter {
                $0.status == .approved && $0.user?.id == userId
            }

            // Schedule pickup alerts for approved reservations
            for reservation in activeReservations {
                NotificationService.shared.schedulePickupAlert(for: reservation, modelContext: modelContext)
            }

            // ✅ Upcoming book reservations
            upcomingBookReservations = allReservations.filter {
                ($0.status == .pending || $0.status == .approved) && $0.user?.id == userId
            }.sorted { $0.createdAt > $1.createdAt }

            // ✅ Upcoming hall reservations
            let allHallReservations = try modelContext.fetch(FetchDescriptor<HallReservation>())
            upcomingHallReservations = allHallReservations
                .filter { $0.userId == userId && $0.status == .confirmed }
                .sorted { $0.bookingDate < $1.bookingDate }

            // ✅ Reading sessions — userId is a flat UUID, safe to predicate
            let sessionDescriptor = FetchDescriptor<ReadingSession>(
                predicate: #Predicate<ReadingSession> { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            let userSessions = try modelContext.fetch(sessionDescriptor)

            readingStreak = calculateStreak(from: userSessions)
            rewardPoints = userSessions.reduce(0) { $0 + ($1.minutes / 10) + $1.challengeBonus }

        } catch {
            errorMessage = "Failed to load home data."
        }
    }

    // MARK: - Helpers

    private func calculateStreak(from sessions: [ReadingSession]) -> Int {
        // sessions are already sorted newest → oldest
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current

        // Collect unique days that had a session
        let uniqueDays: [Date] = sessions
            .map { calendar.startOfDay(for: $0.startedAt) }
            .reduce(into: [Date]()) { result, day in
                if result.last != day { result.append(day) }
            }

        guard let mostRecentDay = uniqueDays.first else { return 0 }

        // Streak only counts if the most recent session was today or yesterday
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard mostRecentDay == today || mostRecentDay == yesterday else { return 0 }

        var streak = 1
        for i in 1 ..< uniqueDays.count {
            let expected = calendar.date(byAdding: .day, value: -i, to: mostRecentDay)!
            if uniqueDays[i] == expected {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
