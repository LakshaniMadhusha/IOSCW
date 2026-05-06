import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ReadingSession]
    
    let user: AppUser
    @State private var vm = HomeViewModel()
    @State private var searchText = ""
    @State private var showingTracker = false
    @State private var showingHistory = false
    @State private var showingNotifications = false
    @State private var bookingReceiptURL: URL?
    @State private var isGeneratingReceipt = false

    @Query private var allNotifications: [AppNotification]

    var body: some View {
        let todayMins = sessions.filter { Calendar.current.isDateInToday($0.startedAt) }.reduce(0) { $0 + $1.minutes }
        let goalProgress = min(1.0, 0.1 + (Double(todayMins) / 120.0) * 0.9)
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // 1. Native Custom Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        TextField("Search books", text: $searchText)
                        Spacer()
                        Image(systemName: "mic.fill")
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // 2. Monthly Challenge Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Monthly Challenge")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        Text("Read 3 Sci-Fi books this month")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * 0.66, height: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.top, 6)
                        
                        HStack {
                            Text("2/3 Books")
                            Spacer()
                            Text("+500 Pts")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(colors: [Color.purple.opacity(0.8), Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.indigo.opacity(0.4), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 20)

                    // 3. Stats Grid
                    HStack(spacing: 16) {
                        // Reading Streak
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Reading\nStreak")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.orange)
                                    .font(.callout)
                                    .padding(8)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(vm.readingStreak) Days")
                                    .font(.title2.weight(.bold))
                                Text("Keep it up!")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .cornerRadius(20)

                        // Total Points
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Total\nPoints")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.callout)
                                    .padding(8)
                                    .background(Color.yellow.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(max(vm.rewardPoints, 1850))")
                                    .font(.title2.weight(.bold))
                                Text("Top 15% of readers")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .cornerRadius(20)
                    }
                    .padding(.horizontal, 20)

                    // 4. Quick Actions
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: LoansView(userId: user.id)) {
                            QuickActionView(title: "My Loans", icon: "book.fill")
                        }
                        NavigationLink(destination: ReadingProgressView(user: user)) {
                            QuickActionView(title: "Progress", icon: "chart.bar.fill")
                        }
                        NavigationLink(destination: ReadingTrackerView(user: user, activeLoans: vm.activeLoans)) {
                            QuickActionView(title: "Track Reading", icon: "timer")
                        }
                        NavigationLink(destination: HallBookingView(user: user)) {
                            QuickActionView(title: "Hall Booking", icon: "building.columns.fill")
                        }
                    }
                    .padding(.horizontal, 20)

                    // 5. Upcoming
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming")
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                if vm.upcomingHallReservations.isEmpty && vm.upcomingBookReservations.isEmpty {
                                    UpcomingCardView(icon: "calendar", iconColor: .purple, title: "No upcoming bookings", subtitle: "Reserve a book, room, or seat to see it here")
                                } else {
                                    ForEach(vm.upcomingBookReservations) { reservation in
                                        UpcomingCardView(
                                            icon: "book.fill",
                                            iconColor: .blue,
                                            title: reservation.book?.title ?? "Unknown Book",
                                            subtitle: "Status: \(reservation.status.rawValue) • Reserved: \(reservation.createdAt.formatted(date: .abbreviated, time: .shortened))"
                                        )
                                    }
                                    ForEach(vm.upcomingHallReservations) { reservation in
                                        UpcomingCardView(
                                            icon: "qrcode",
                                            iconColor: .purple,
                                            title: reservation.hallName,
                                            subtitle: "\(reservation.reservationType.rawValue): \(reservation.reservationDetails) • \(reservation.bookingDate.formatted(date: .abbreviated, time: .shortened))",
                                            action: {
                                                isGeneratingReceipt = true
                                                Task {
                                                    if let url = PDFService.shared.generateBookingReceipt(user: user, reservation: reservation) {
                                                        bookingReceiptURL = url
                                                    }
                                                    isGeneratingReceipt = false
                                                }
                                            },
                                            isActionLoading: isGeneratingReceipt
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // 6. Carousels
                    if !vm.activeLoans.isEmpty {
                        SectionCarouselView(title: "Current Reading", books: vm.activeLoans.compactMap { $0.book }, user: user)
                    }
                    if !vm.featuredBooks.isEmpty {
                        SectionCarouselView(title: "Top Picks", books: vm.featuredBooks, user: user)
                        SectionCarouselView(title: "Siri Suggestions", books: vm.featuredBooks.reversed(), user: user)
                    }

                    // 7. Reading Goals
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Reading Goals")
                            .font(.title3.weight(.bold))
                        
                        VStack(spacing: 24) {
                            ZStack {
                                // Background Track
                                Circle()
                                    .trim(from: 0.1, to: 0.9)
                                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(90))
                                    .frame(width: 220, height: 220)

                                // Progress Fill
                                Circle()
                                    .trim(from: 0.1, to: goalProgress)
                                    .stroke(
                                        LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(90))
                                    .frame(width: 220, height: 220)
                                    .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 0)
                                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: goalProgress)

                                // Center Text
                                VStack(spacing: 4) {
                                    Text("Today's Progress")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.textPrimary)
                                    Text("\(Int(min(1.0, Double(todayMins) / 120.0) * 100))%")
                                        .font(.system(size: 44, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                        .contentTransition(.numericText())
                                    Text("\(todayMins) / 120 mins")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .offset(y: -10)
                            }
                            .frame(height: 180) // Cliped area for bottom
                            .clipped()

                            VStack(spacing: 12) {
                                Button(action: { showingTracker = true }) {
                                    Text("Keep Reading")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                }

                                Button(action: { showingHistory = true }) {
                                    Text("Reading History")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.purple.opacity(0.1))
                                        .foregroundColor(.purple)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .padding(.bottom, 40)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: { showingNotifications = true }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                
                                let unreadCount = allNotifications.filter { ($0.userId == user.id || $0.userId == nil) && !$0.isRead }.count
                                if unreadCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 10, height: 10)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.purple, .purple.opacity(0.2))
                    }
                }
            }
        }
        .task { await vm.load(user: user, modelContext: modelContext) }
        .onChange(of: sessions) { _, _ in
            Task { await vm.load(user: user, modelContext: modelContext) }
        }
        .sheet(isPresented: $showingTracker) {
            ReadingTrackerView(user: user, activeLoans: vm.activeLoans)
        }
        .sheet(isPresented: $showingHistory) {
            ReadingHistoryView(userId: user.id)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView(userId: user.id)
        }
        .sheet(item: $bookingReceiptURL) { url in
            ActivityView(activityItems: [url])
        }
    }
}

// MARK: - Subcomponents

struct QuickActionView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 65, height: 65)
                .background(Color.cardBg)
                .cornerRadius(20)
                .foregroundColor(.textPrimary)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct UpcomingCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var isActionLoading: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(iconColor.opacity(0.15))
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            
            if let action = action {
                Spacer()
                Button(action: action) {
                    if isActionLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                    }
                }
                .disabled(isActionLoading)
            }
        }
        .padding(16)
        .frame(width: action != nil ? 280 : 240, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SectionCarouselView: View {
    let title: String
    let books: [Book]
    let user: AppUser

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.title3.weight(.bold))
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("See All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.purple)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(books) { book in
                        NavigationLink(destination: BookDetailView(book: book, user: user)) {
                            BookCoverCard(book: book, width: 110, height: 165)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
