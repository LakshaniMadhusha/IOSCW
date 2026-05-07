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

            // ✅ Featured books
            featuredBooks = try modelContext
                .fetch(FetchDescriptor<Book>())
                .shuffled()
                .prefix(4)
                .map { $0 }

            // ✅ Active loans
            let allLoans = try modelContext.fetch(FetchDescriptor<Loan>())
            activeLoans = allLoans.filter {
                $0.returnedAt == nil && $0.user?.id == userId
            }

            // Schedule due date reminders
            for loan in activeLoans {
                NotificationService.shared.scheduleDueDateReminder(for: loan, modelContext: modelContext)
            }

            // ✅ Approved reservations
            let allReservations = try modelContext.fetch(FetchDescriptor<Reservation>())
            activeReservations = allReservations.filter {
                $0.status == .approved && $0.user?.id == userId
            }

            // Schedule pickup alerts
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

            // ✅ Reading sessions
            let sessionDescriptor = FetchDescriptor<ReadingSession>(
                predicate: #Predicate<ReadingSession> { session in
                    session.userId == userId
                },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            let userSessions = try modelContext.fetch(sessionDescriptor)

            readingStreak = calculateStreak(from: userSessions)
            rewardPoints = userSessions.reduce(0) { $0 + ($1.minutes / 10) + $1.challengeBonus }

            // ✅ Sync to Smart Widget
            let provider = WidgetDataProvider.shared
            provider.updatePoints(rewardPoints)
            provider.updateStreak(readingStreak)
            
            // Sync most urgent book due date with Shelf Assistant
            if let mostUrgentLoan = activeLoans.sorted(by: { $0.dueAt < $1.dueAt }).first {
                provider.updateNextDue(
                    title: mostUrgentLoan.book?.title ?? "Book", 
                    date: mostUrgentLoan.dueAt, 
                    shelf: mostUrgentLoan.book?.shelfCode
                )
            }
            
            // Sync next hall reservation with location
            if let nextHall = upcomingHallReservations.first {
                let hallName = nextHall.hallName
                // Try to find the hall coordinates (Mock or fetch)
                provider.updateNextReservation(title: hallName, date: nextHall.bookingDate)
            }
            
            // Sync daily reading goal
            let todayMins = userSessions.filter { Calendar.current.isDateInToday($0.startedAt) }.reduce(0) { $0 + $1.minutes }
            provider.updateReadingProgress(minutes: todayMins, goal: 30)

            // Seed Test Books for VisionKit Testing
            seedTestData(modelContext: modelContext)

        } catch {
            errorMessage = "Failed to load home data."
        }
    }

    // MARK: - Helpers

    private func calculateStreak(from sessions: [ReadingSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        let uniqueDays: [Date] = sessions
            .map { calendar.startOfDay(for: $0.startedAt) }
            .reduce(into: [Date]()) { result, day in
                if result.last != day { result.append(day) }
            }
        guard let mostRecentDay = uniqueDays.first else { return 0 }
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

    @MainActor
    private func seedTestData(modelContext: ModelContext) {
        let existingBooks = try? modelContext.fetch(FetchDescriptor<Book>())
        if let existing = existingBooks, !existing.contains(where: { $0.isbn == "9780743273565" }) {
            let gatsby = Book(
                title: "The Great Gatsby",
                author: "F. Scott Fitzgerald",
                genre: "Classic Literature",
                isbn: "9780743273565",
                shelfCode: "A-12"
            )
            modelContext.insert(gatsby)
        }
        if let existing = existingBooks, !existing.contains(where: { $0.isbn == "9780142437230" }) {
            let quixote = Book(
                title: "Don Quixote",
                author: "Miguel de Cervantes",
                genre: "Adventure",
                isbn: "9780142437230",
                shelfCode: "B-05"
            )
            modelContext.insert(quixote)
        }
        try? modelContext.save()
    }
}
