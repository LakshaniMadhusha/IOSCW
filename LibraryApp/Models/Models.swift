import Foundation
import SwiftData

enum UserRole: String, Codable, CaseIterable {
    case member = "Member"
    case librarian = "Librarian"
}

@Model
final class AppUser: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var password: String // Mandatory DB parameter
    var roleRaw: String
    var isBiometricEnabled: Bool
    
    // Core Registration Form Analytics
    var membershipId: String?
    var phoneNumber: String?
    var address: String?
    
    // New Profile Details
    var occupation: String?
    var bio: String?
    var favoriteGenre: String?
    
    var createdAt: Date
    var profileImageData: Data?

    init(id: UUID = UUID(), name: String, email: String, password: String = "", role: UserRole, isBiometricEnabled: Bool = false, membershipId: String? = nil, phoneNumber: String? = nil, address: String? = nil, createdAt: Date = .now, profileImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.roleRaw = role.rawValue
        self.isBiometricEnabled = isBiometricEnabled
        self.membershipId = membershipId
        self.phoneNumber = phoneNumber
        self.address = address
        self.occupation = nil
        self.bio = nil
        self.favoriteGenre = nil
        self.createdAt = createdAt
        self.profileImageData = profileImageData
    }

    var role: UserRole {
        get { UserRole(rawValue: roleRaw) ?? .member }
        set { roleRaw = newValue.rawValue }
    }
}

enum BookStatus: String, Codable, CaseIterable {
    case available = "Available"
    case reserved = "Reserved"
    case onLoan = "On Loan"
}

@Model
final class Book: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String
    var genre: String
    var summary: String
    var status: BookStatus
    var rating: Double
    var coverUrl: String?
    var pdfUrl: String?
    var isbn: String?
    var shelfCode: String
    var branch: String
    var totalCopies: Int
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade) var loans: [Loan] = []
    @Relationship(deleteRule: .cascade) var reservations: [Reservation] = []

    init(id: UUID = UUID(), title: String, author: String, genre: String, summary: String = "", status: BookStatus = .available, rating: Double = 0, coverUrl: String? = nil, pdfUrl: String? = nil, isbn: String? = nil, shelfCode: String = "", branch: String = "Main Branch", totalCopies: Int = 1, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.summary = summary
        self.status = status
        self.rating = rating
        self.coverUrl = coverUrl
        self.pdfUrl = pdfUrl
        self.isbn = isbn
        self.shelfCode = shelfCode
        self.branch = branch
        self.totalCopies = totalCopies
        self.createdAt = createdAt
    }

    // Computed properties for availability intelligence
    var availableCopies: Int {
        let activeLoans = loans.filter { $0.isActive }
        return max(0, totalCopies - activeLoans.count)
    }

    var waitingQueueCount: Int {
        reservations.filter { $0.status == .pending || $0.status == .approved }.count
    }

    var isAvailable: Bool {
        availableCopies > 0
    }

    var estimatedWaitTime: String {
        if waitingQueueCount == 0 {
            return "Available now"
        } else if waitingQueueCount == 1 {
            return "1 person waiting"
        } else {
            return "\(waitingQueueCount) people waiting"
        }
    }

    // Related books (computed based on same genre)
    func getRelatedBooks(from allBooks: [Book]) -> [Book] {
        allBooks.filter { $0.id != self.id && $0.genre == self.genre }.prefix(5).map { $0 }
    }

    // Reading challenge relevance
    func getChallengeRelevance() -> [String] {
        var relevance: [String] = []

        // Genre-based challenges
        switch genre.lowercased() {
        case "fiction":
            relevance.append("Fiction Master Challenge")
        case "non-fiction", "biography":
            relevance.append("Knowledge Seeker Challenge")
        case "science fiction":
            relevance.append("Sci-Fi Explorer Challenge")
        case "mystery", "thriller":
            relevance.append("Mystery Solver Challenge")
        case "romance":
            relevance.append("Romance Reader Challenge")
        default:
            relevance.append("Diverse Reader Challenge")
        }

        // Rating-based challenges
        if rating >= 4.5 {
            relevance.append("Bestseller Challenge")
        }

        // Length-based (if we had page count, we could add more)

        return relevance
    }
}

@Model
final class Loan: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var dueAt: Date
    var returnedAt: Date?

    var user: AppUser?
    var book: Book?

    init(id: UUID = UUID(), createdAt: Date = .now, dueAt: Date, returnedAt: Date? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.returnedAt = returnedAt
    }

    var isActive: Bool { returnedAt == nil }
    var isOverdue: Bool { isActive && dueAt < .now }
}

enum ReservationStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case approved = "Approved"
    case cancelled = "Cancelled"
    case fulfilled = "Fulfilled"
}

@Model
final class Reservation: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var statusRaw: String

    var user: AppUser?
    var book: Book?

    var status: ReservationStatus {
        get { ReservationStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), createdAt: Date = .now, status: ReservationStatus = .pending) {
        self.id = id
        self.createdAt = createdAt
        self.statusRaw = status.rawValue
    }
}

enum SeatStatus: String, Codable, CaseIterable {
    case available = "Available"
    case occupied = "Occupied"
    case reserved = "Reserved"
}

@Model
final class Hall: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String
    var floor: Int
    var latitude: Double
    var longitude: Double

    @Relationship(deleteRule: .cascade) var seats: [Seat]
    @Relationship(deleteRule: .cascade) var events: [HallEvent]

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        floor: Int,
        latitude: Double,
        longitude: Double,
        seats: [Seat] = [],
        events: [HallEvent] = []
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.floor = floor
        self.latitude = latitude
        self.longitude = longitude
        self.seats = seats
        self.events = events
    }
}

@Model
final class HallEvent: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var eventDescription: String

    @Relationship(deleteRule: .nullify) var hall: Hall?

    init(id: UUID = UUID(), title: String, date: Date, eventDescription: String, hall: Hall? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.eventDescription = eventDescription
        self.hall = hall
    }
}

@Model
final class Seat: Identifiable {
    @Attribute(.unique) var id: UUID
    var label: String
    var row: Int
    var column: Int
    var status: SeatStatus
    var reservedUntil: Date?

    init(id: UUID = UUID(), label: String, row: Int, column: Int, status: SeatStatus = .available, reservedUntil: Date? = nil) {
        self.id = id
        self.label = label
        self.row = row
        self.column = column
        self.status = status
        self.reservedUntil = reservedUntil
    }
}

enum ReservationType: String, Codable, CaseIterable {
    case event = "Event"
    case seat = "Seat"
}

enum HallReservationStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

@Model
final class HallReservation: Identifiable {
    @Attribute(.unique) var id: UUID
    var hallName: String
    var hallAddress: String
    var reservationTypeRaw: String
    var reservationDetails: String
    var bookingDate: Date
    var bookingHours: Int
    var attendeeCount: Int
    var qrCodeData: String?
    var statusRaw: String
    var userId: UUID
    var createdAt: Date

    var user: AppUser?

    var reservationType: ReservationType {
        get { ReservationType(rawValue: reservationTypeRaw) ?? .seat }
        set { reservationTypeRaw = newValue.rawValue }
    }

    var status: HallReservationStatus {
        get { HallReservationStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        hallName: String,
        hallAddress: String,
        reservationType: ReservationType,
        reservationDetails: String,
        bookingDate: Date,
        bookingHours: Int = 2,
        attendeeCount: Int = 1,
        qrCodeData: String? = nil,
        status: HallReservationStatus = .confirmed,
        userId: UUID,
        createdAt: Date = .now
    ) {
        self.id = id
        self.hallName = hallName
        self.hallAddress = hallAddress
        self.reservationTypeRaw = reservationType.rawValue
        self.reservationDetails = reservationDetails
        self.bookingDate = bookingDate
        self.bookingHours = bookingHours
        self.attendeeCount = attendeeCount
        self.qrCodeData = qrCodeData
        self.statusRaw = status.rawValue
        self.userId = userId
        self.createdAt = createdAt
    }
}

@Model
final class ReadingSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var minutes: Int
    var userId: UUID
    var challengeName: String?
    var challengeBonus: Int

    var user: AppUser?
    var book: Book?

    init(id: UUID = UUID(), startedAt: Date = .now, minutes: Int = 0, userId: UUID, challengeName: String? = nil, challengeBonus: Int = 0) {
        self.id = id
        self.startedAt = startedAt
        self.minutes = minutes
        self.userId = userId
        self.challengeName = challengeName
        self.challengeBonus = challengeBonus
    }
}

@Model
final class Badge: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var earnedAt: Date

    var user: AppUser?

    init(id: UUID = UUID(), title: String, earnedAt: Date = .now) {
        self.id = id
        self.title = title
        self.earnedAt = earnedAt
    }
}

@Model
final class AppNotification: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var message: String
    var category: String
    var createdAt: Date
    var userId: UUID?
    var isRead: Bool

    init(id: UUID = UUID(), title: String, message: String, category: String, createdAt: Date = .now, userId: UUID? = nil, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.category = category
        self.createdAt = createdAt
        self.userId = userId
        self.isRead = isRead
    }
}
