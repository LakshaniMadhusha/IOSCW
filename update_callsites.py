import os
import re

def replace_in_file(path, old, new):
    if not os.path.exists(path): return
    with open(path, "r") as f:
        content = f.read()
    if old in content:
        content = content.replace(old, new)
        with open(path, "w") as f:
            f.write(content)

# 1. HallDetailView
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Halls/HallDetailView.swift",
    "NotificationService.shared.scheduleSeatConfirmation(for: reservation)",
    "NotificationService.shared.scheduleSeatConfirmation(for: reservation, modelContext: modelContext)"
)

# 2. BookDetailView
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Books/BookDetailView.swift",
    "NotificationService.shared.scheduleBookReservationConfirmation(for: book.title)",
    "if let userId = user?.id { NotificationService.shared.scheduleBookReservationConfirmation(for: book.title, userId: userId, modelContext: modelContext) }"
)

# 3. HomeViewModel
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Home/HomeViewModel.swift",
    "NotificationService.shared.scheduleDueDateReminder(for: loan)",
    "NotificationService.shared.scheduleDueDateReminder(for: loan, modelContext: modelContext)"
)
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Home/HomeViewModel.swift",
    "NotificationService.shared.schedulePickupAlert(for: reservation)",
    "NotificationService.shared.schedulePickupAlert(for: reservation, modelContext: modelContext)"
)

# 4. HallBookingView
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Halls/HallBookingView.swift",
    '''NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: selectedHall.name,
            hallAddress: selectedHall.address,
            detailsDescription: "Your event reservation is now in Upcoming."
        )''',
    '''NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: selectedHall.name,
            hallAddress: selectedHall.address,
            detailsDescription: "Your event reservation is now in Upcoming.",
            userId: user.id,
            modelContext: modelContext
        )'''
)
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Halls/HallBookingView.swift",
    '''NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: selectedHall.name,
            hallAddress: selectedHall.address,
            detailsDescription: "Your seat reservation is now in Upcoming."
        )''',
    '''NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: selectedHall.name,
            hallAddress: selectedHall.address,
            detailsDescription: "Your seat reservation is now in Upcoming.",
            userId: user.id,
            modelContext: modelContext
        )'''
)

# 5. DashboardView
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Librarian/Dashboard/DashboardView.swift",
    "NotificationService.shared.scheduleLibrarianAnnouncement(title: announcementTitle, message: announcementMessage)",
    "NotificationService.shared.scheduleLibrarianAnnouncement(title: announcementTitle, message: announcementMessage, modelContext: modelContext)"
)

# 6. ReadingTrackerView
replace_in_file(
    "/Users/cobsccomp242p-062/Documents/SmartLibrary-main-2/LibraryApp/Member/Reading/ReadingTrackerView.swift",
    'NotificationService.shared.scheduleChallengeMilestone(userId: user.id, milestone: "Read for \\(minutes) minutes!")',
    'NotificationService.shared.scheduleChallengeMilestone(userId: user.id, milestone: "Read for \\(minutes) minutes!", modelContext: modelContext)'
)
