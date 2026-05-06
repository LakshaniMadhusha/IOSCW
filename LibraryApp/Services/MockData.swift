import Foundation
import SwiftData

enum MockData {
    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) throws {
        let existingUsers = try modelContext.fetchCount(FetchDescriptor<AppUser>())
        guard existingUsers == 0 else { return }

        let member = AppUser(name: "Sarah Evans", email: "sarah@library.com", role: .member)
        let librarian = AppUser(name: "Mike Johnson", email: "mike@library.com", role: .librarian)

        let books: [Book] = [
            Book(
                title: "Tick Tack",
                author: "James R.",
                genre: "Thriller",
                summary: "A heart-pounding thriller that keeps you on the edge of your seat with every twist and turn. When Detective Sarah Miller discovers a series of seemingly unrelated murders, she uncovers a conspiracy that goes deeper than she ever imagined.",
                status: .onLoan,
                rating: 4.5,
                shelfCode: "THR-001",
                branch: "Main Branch",
                totalCopies: 3
            ),
            Book(
                title: "The Big Empty",
                author: "Sarah M.",
                genre: "Fiction",
                summary: "An introspective novel about finding meaning in the vast emptiness of modern life. Follow the journey of a young artist as she navigates love, loss, and self-discovery in the sprawling landscapes of the American West.",
                status: .available,
                rating: 4.2,
                shelfCode: "FIC-045",
                branch: "Main Branch",
                totalCopies: 5
            ),
            Book(
                title: "Robert Craig",
                author: "R. Craig",
                genre: "Mystery",
                summary: "A classic whodunit mystery set in the foggy streets of Victorian London. When a wealthy businessman is found murdered in his study, Inspector Hawthorne must unravel a web of deceit, betrayal, and hidden family secrets.",
                status: .available,
                rating: 4.7,
                shelfCode: "MYS-012",
                branch: "Downtown Branch",
                totalCopies: 2
            ),
            Book(
                title: "Don't Blink",
                author: "K. Patterson",
                genre: "Thriller",
                summary: "In this gripping psychological thriller, a successful lawyer's perfect life begins to unravel when she starts receiving anonymous threats. As the stakes escalate, she must confront her past and fight for survival.",
                status: .reserved,
                rating: 4.3,
                shelfCode: "THR-023",
                branch: "Main Branch",
                totalCopies: 4
            ),
        ]

        let hallA = Hall(
            name: "Reading Room A",
            address: "123 Library Lane",
            floor: 1,
            latitude: 37.3317,
            longitude: -122.0307,
            seats: generateSeats(rows: 5, cols: 8)
        )

        let event1 = HallEvent(
            title: "Author Talk: Modern Poetry",
            date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
            eventDescription: "Reserve a seat for an evening with local poets and open mic performances.",
            hall: hallA
        )
        let event2 = HallEvent(
            title: "Library Film Night",
            date: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
            eventDescription: "Enjoy a curated documentary screening with refreshments and discussion.",
            hall: hallA
        )
        hallA.events = [event1, event2]

        let hallB = Hall(
            name: "Study Hall B",
            address: "48 Book Street",
            floor: 2,
            latitude: 37.3328,
            longitude: -122.0283,
            seats: generateSeats(rows: 4, cols: 6)
        )

        let event3 = HallEvent(
            title: "Exam Prep Q&A",
            date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            eventDescription: "Bring your questions and get advice from study coaches.",
            hall: hallB
        )
        let event4 = HallEvent(
            title: "Research Skills Session",
            date: Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now,
            eventDescription: "Learn how to use library archives, databases, and citation tools effectively.",
            hall: hallB
        )
        hallB.events = [event3, event4]

        modelContext.insert(member)
        modelContext.insert(librarian)
        books.forEach(modelContext.insert)
        modelContext.insert(hallA)
        modelContext.insert(hallB)
        modelContext.insert(event1)
        modelContext.insert(event2)
        modelContext.insert(event3)
        modelContext.insert(event4)

        // Seed a few reading sessions for charts
        for daysAgo in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
            let minutes = Int.random(in: 10...75)
            let session = ReadingSession(startedAt: date, minutes: minutes, userId: member.id)
            session.user = member
            session.book = books.randomElement()
            modelContext.insert(session)
        }

        // Seed an active loan
        let due = Calendar.current.date(byAdding: .day, value: 6, to: .now) ?? .now
        let loan = Loan(dueAt: due)
        loan.user = member
        loan.book = books.first
        modelContext.insert(loan)

        // Seed some reservations for waiting queue demo
        let reservation1 = Reservation(status: .pending)
        reservation1.user = member
        reservation1.book = books[3] // Don't Blink
        modelContext.insert(reservation1)

        let reservation2 = Reservation(status: .approved)
        reservation2.user = librarian
        reservation2.book = books[3] // Don't Blink
        modelContext.insert(reservation2)

        try modelContext.save()
    }

    private static func generateSeats(rows: Int, cols: Int) -> [Seat] {
        var seats: [Seat] = []
        for row in 0..<rows {
            for col in 0..<cols {
                let label = "\(Character(UnicodeScalar(65 + row)!))\(col + 1)"
                let status: SeatStatus = [.available, .available, .available, .occupied, .reserved].randomElement() ?? .available
                seats.append(Seat(label: label, row: row, column: col, status: status))
            }
        }
        return seats
    }
}

