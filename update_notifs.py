import re

path = "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Services/NotificationService.swift"

with open(path, "r") as f:
    content = f.read()

# 1. scheduleDueDateReminder
content = content.replace(
    "func scheduleDueDateReminder(for loan: Loan, daysBefore: Int = 1) {",
    "func scheduleDueDateReminder(for loan: Loan, modelContext: ModelContext? = nil, daysBefore: Int = 1) {"
)
content = content.replace(
    'content.categoryIdentifier = "DUE_REMINDER"\n',
    '''content.categoryIdentifier = "DUE_REMINDER"

        if let context = modelContext, let user = loan.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reminder", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 2. schedulePickupAlert
content = content.replace(
    "func schedulePickupAlert(for reservation: Reservation) {",
    "func schedulePickupAlert(for reservation: Reservation, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "PICKUP_ALERT"\n',
    '''content.categoryIdentifier = "PICKUP_ALERT"

        if let context = modelContext, let user = reservation.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "pickup", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 3. scheduleSeatConfirmation
content = content.replace(
    "func scheduleSeatConfirmation(for reservation: Reservation) {",
    "func scheduleSeatConfirmation(for reservation: Reservation, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "SEAT_CONFIRMATION"\n',
    '''content.categoryIdentifier = "SEAT_CONFIRMATION"

        if let context = modelContext, let user = reservation.user {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: user.id)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 4. scheduleChallengeMilestone
content = content.replace(
    "func scheduleChallengeMilestone(userId: UUID, milestone: String) {",
    "func scheduleChallengeMilestone(userId: UUID, milestone: String, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "CHALLENGE_MILESTONE"\n',
    '''content.categoryIdentifier = "CHALLENGE_MILESTONE"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "challenge", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 5. scheduleLibrarianAnnouncement
content = content.replace(
    "func scheduleLibrarianAnnouncement(title: String, message: String) {",
    "func scheduleLibrarianAnnouncement(title: String, message: String, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "LIBRARIAN_ANNOUNCEMENT"\n',
    '''content.categoryIdentifier = "LIBRARIAN_ANNOUNCEMENT"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "announcement", userId: nil)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 6. scheduleHallBookingConfirmation
content = content.replace(
    "func scheduleHallBookingConfirmation(hallName: String, hallAddress: String, detailsDescription: String) {",
    "func scheduleHallBookingConfirmation(hallName: String, hallAddress: String, detailsDescription: String, userId: UUID, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "HALL_BOOKING_CONFIRMATION"\n',
    '''content.categoryIdentifier = "HALL_BOOKING_CONFIRMATION"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

# 7. scheduleBookReservationConfirmation
content = content.replace(
    "func scheduleBookReservationConfirmation(for bookTitle: String) {",
    "func scheduleBookReservationConfirmation(for bookTitle: String, userId: UUID, modelContext: ModelContext? = nil) {"
)
content = content.replace(
    'content.categoryIdentifier = "BOOK_RESERVATION_CONFIRMATION"\n',
    '''content.categoryIdentifier = "BOOK_RESERVATION_CONFIRMATION"

        if let context = modelContext {
            let appNotif = AppNotification(title: content.title, message: content.body, category: "reservation", userId: userId)
            context.insert(appNotif)
            try? context.save()
        }
'''
)

with open(path, "w") as f:
    f.write(content)
