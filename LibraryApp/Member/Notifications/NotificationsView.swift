import SwiftUI
import SwiftData

struct NotificationsView: View {
    let userId: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var notifications: [AppNotification]

    init(userId: UUID) {
        self.userId = userId
        let id = userId
        // Sort by createdAt descending
        _notifications = Query(
            filter: #Predicate<AppNotification> { notif in
                notif.userId == id || notif.userId == nil
            },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()

                if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.textSecondary)
                        Text("No Notifications")
                            .font(.title2.weight(.bold))
                        Text("You're all caught up! System alerts will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    if !notification.isRead {
                                        notification.isRead = true
                                        try? modelContext.save()
                                    }
                                }
                        }
                        .onDelete(perform: deleteNotifications)
                    }
                    .listStyle(.plain)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                            .font(.title3)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !notifications.isEmpty {
                        Button("Mark All Read") {
                            for notification in notifications {
                                notification.isRead = true
                            }
                            try? modelContext.save()
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private func deleteNotifications(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notifications[index])
        }
        try? modelContext.save()
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var iconData: (icon: String, color: Color) {
        switch notification.category {
        case "reminder": return ("clock.fill", .orange)
        case "pickup": return ("bag.fill", .green)
        case "reservation": return ("calendar.badge.clock", .purple)
        case "challenge": return ("star.fill", .yellow)
        case "announcement": return ("megaphone.fill", .blue)
        default: return ("bell.fill", .gray)
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconData.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: iconData.icon)
                    .foregroundColor(iconData.color)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 2)
            }

            Spacer()

            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(Color.cardBg)
        .cornerRadius(16)
        .opacity(notification.isRead ? 0.6 : 1.0)
    }
}
