import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var books: [Book]
    @Query private var loans: [Loan]
    @State private var showingAnnouncement = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\AppNotification.createdAt, order: .reverse)]) private var allNotifications: [AppNotification]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    KPIGrid(books: books, loans: loans)
                        .lightCard()

                    CirculationChartView(loans: loans)
                        .lightCard()

                    Button {
                        showingAnnouncement = true
                    } label: {
                        HStack {
                            Image(systemName: "megaphone.fill")
                            Text("Broadcast Announcement")
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .padding(20)
                        .background(
                            LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(24)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 20)
                    
                    // 4. Announcement History
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Broadcast History")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("\(allNotifications.filter { $0.category == "announcement" }.count) Sent")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        let announcements = allNotifications.filter { $0.category == "announcement" }
                        
                        if announcements.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary.opacity(0.3))
                                Text("No announcements sent yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color.cardBg)
                            .cornerRadius(24)
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(announcements.prefix(5)) { announcement in
                                    AnnouncementHistoryRow(announcement: announcement)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingAnnouncement) {
                AnnouncementComposerView()
                    .environment(\EnvironmentValues.modelContext, modelContext)
            }
        }
    }
}

private struct KPIGrid: View {
    let books: [Book]
    let loans: [Loan]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                KPICardView(title: "Total books", value: "\(books.count)", icon: "books.vertical.fill", tint: .primary)
                KPICardView(title: "Active loans", value: "\(loans.filter(\.isActive).count)", icon: "bookmark.fill", tint: .amber)
                KPICardView(title: "Overdue", value: "\(loans.filter(\.isOverdue).count)", icon: "exclamationmark.triangle.fill", tint: .coral)
                KPICardView(title: "Available", value: "\(books.filter { $0.status == .available }.count)", icon: "checkmark.seal.fill", tint: .teal)
            }
        }
        .padding(16)
    }
}

struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.surfaceBg)
        .cornerRadius(14)
    }
}

struct CirculationChartView: View {
    struct Bucket: Identifiable {
        let id = UUID()
        let day: Date
        let count: Int
    }

    let loans: [Loan]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Circulation (last 14 days)")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Chart(buckets) { b in
                BarMark(
                    x: .value("Day", b.day, unit: .day),
                    y: .value("Loans", b.count)
                )
                .foregroundStyle(Color.accent)
                .cornerRadius(4)
            }
            .frame(height: 180)
        }
        .padding(16)
    }

    private var buckets: [Bucket] {
        let start = Calendar.current.date(byAdding: .day, value: -13, to: .now) ?? .now
        let days = (0..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
        let grouped = Dictionary(grouping: loans) { loan in
            Calendar.current.startOfDay(for: loan.createdAt)
        }.mapValues { $0.count }

        return days.map { day in
            Bucket(day: day, count: grouped[Calendar.current.startOfDay(for: day)] ?? 0)
        }
    }
}

struct AnnouncementHistoryRow: View {
    let announcement: AppNotification
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let isUrgent = announcement.title.contains("[Urgent]")
                let isImportant = announcement.title.contains("[Important]")
                
                Label(isUrgent ? "Urgent" : (isImportant ? "Important" : "General"), 
                      systemImage: isUrgent ? "exclamationmark.triangle.fill" : (isImportant ? "exclamationmark.circle" : "info.circle"))
                    .font(.caption2.weight(.bold))
                    .foregroundColor(isUrgent ? .red : (isImportant ? .orange : .blue))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isUrgent ? Color.red.opacity(0.1) : (isImportant ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1)))
                    .cornerRadius(6)
                
                Spacer()
                
                Text(announcement.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(announcement.title.replacingOccurrences(of: "\\[.*?\\] ", with: "", options: .regularExpression))
                .font(.subheadline.weight(.bold))
                .foregroundColor(.textPrimary)
            
            Text(announcement.message)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}


