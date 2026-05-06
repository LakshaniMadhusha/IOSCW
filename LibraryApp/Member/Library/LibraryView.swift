import SwiftUI
import SwiftData

// MARK: - Library Tab Enum
enum LibraryTab: String, CaseIterable {
    case reading  = "Reading"
    case history  = "History"
    case reserved = "Reserved"
}

// MARK: - Main Library View
struct LibraryView: View {
    @EnvironmentObject var auth: AuthService
    let user: AppUser

    @State private var selectedTab: LibraryTab = .reading
    @Namespace private var tabAnimation

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // ── Background wash ────────────────────────────────────────
                Color.pageBg
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ─────────────────────────────────────────────
                    libraryHeader

                    // ── Custom Segmented Tabs ──────────────────────────────
                    customTabBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // ── Tab Content ────────────────────────────────────────
                    TabView(selection: $selectedTab) {
                        ReadingTabView(user: user)
                            .tag(LibraryTab.reading)

                        HistoryTabView(userId: user.id)
                            .tag(LibraryTab.history)

                        ReservedTabView(userId: user.id)
                            .tag(LibraryTab.reserved)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: Library Header
    private var libraryHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Library")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text("Track your reading journey")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            // Library stats pill
            HStack(spacing: 6) {
                Image(systemName: "books.vertical.fill")
                    .font(.caption.weight(.semibold))
                Text("Library")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(.purpleAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purpleAccent.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(.subheadline.weight(selectedTab == tab ? .bold : .regular))
                            .foregroundColor(selectedTab == tab ? .purpleAccent : .textSecondary)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)

                        // Active indicator
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 3)
                            .foregroundColor(selectedTab == tab ? .purpleAccent : .clear)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBg)
                .shadow(color: Color.purpleAccent.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Reading Tab
struct ReadingTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Loan.dueAt) private var allLoans: [Loan]
    @State private var showReturnAlert = false
    @State private var selectedLoan: Loan?

    let user: AppUser

    private var loans: [Loan] {
        allLoans.filter { $0.user?.id == user.id && $0.returnedAt == nil }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if loans.isEmpty {
                LibraryEmptyState(
                    icon: "book.closed.fill",
                    title: "No Active Books",
                    subtitle: "Borrow books from the library to start your reading journey."
                )
            } else {
                LazyVStack(spacing: 16) {
                    // Stats row
                    HStack(spacing: 12) {
                        LibraryMiniStat(value: "\(loans.count)", label: "Reading", icon: "book.fill", color: .purpleAccent)
                        LibraryMiniStat(value: "\(loans.filter { $0.isOverdue }.count)", label: "Overdue", icon: "exclamationmark.circle.fill", color: .red)
                        LibraryMiniStat(value: "\(loans.filter { !$0.isOverdue }.count)", label: "On Time", icon: "checkmark.circle.fill", color: .teal)
                    }
                    .padding(.top, 4)

                    ForEach(loans) { loan in
                        ActiveLoanCard(loan: loan, user: user, allLoans: allLoans) {
                            selectedLoan = loan
                            showReturnAlert = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.pageBg)
        .alert("Return Book", isPresented: $showReturnAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Return", role: .destructive) {
                if let loan = selectedLoan {
                    loan.returnedAt = .now
                    loan.book?.status = .available
                    try? modelContext.save()
                }
            }
        } message: {
            if let book = selectedLoan?.book {
                Text("Return \"\(book.title)\"? This cannot be undone.")
            }
        }
    }
}

// MARK: - History Tab
struct HistoryTabView: View {
    @Query(sort: \ReadingSession.startedAt, order: .reverse) private var allSessions: [ReadingSession]
    let userId: UUID

    private var sessions: [ReadingSession] {
        allSessions.filter { $0.userId == userId }
    }

    private var totalMinutes: Int { sessions.reduce(0) { $0 + $1.minutes } }
    private var totalPoints: Int  { sessions.reduce(0) { $0 + ($1.minutes / 10) * 10 } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if sessions.isEmpty {
                LibraryEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No Reading History",
                    subtitle: "Start a reading session to begin tracking your journey."
                )
            } else {
                LazyVStack(spacing: 16) {
                    // Summary banner
                    HStack(spacing: 12) {
                        LibraryMiniStat(value: "\(sessions.count)", label: "Sessions", icon: "calendar", color: .purpleAccent)
                        LibraryMiniStat(value: "\(totalMinutes)m", label: "Total Read", icon: "timer", color: .amber)
                        LibraryMiniStat(value: "\(totalPoints)", label: "Points", icon: "star.fill", color: .teal)
                    }
                    .padding(.top, 4)

                    ForEach(sessions) { session in
                        HistorySessionCard(session: session)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.pageBg)
    }
}

// MARK: - Reserved Tab
struct ReservedTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reservation.createdAt, order: .reverse) private var allReservations: [Reservation]
    @State private var showCancelAlert = false
    @State private var selectedReservation: Reservation?
    let userId: UUID

    private var reservations: [Reservation] {
        allReservations.filter {
            $0.user?.id == userId &&
            ($0.statusRaw == "Pending" || $0.statusRaw == "Approved")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if reservations.isEmpty {
                LibraryEmptyState(
                    icon: "bookmark.fill",
                    title: "No Reservations",
                    subtitle: "Reserve books from the Discover tab to hold them for you."
                )
            } else {
                LazyVStack(spacing: 16) {
                    LibraryMiniStat(value: "\(reservations.count)", label: "Reserved", icon: "bookmark.fill", color: .purpleAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    ForEach(reservations) { reservation in
                        ReservationCard(reservation: reservation) {
                            selectedReservation = reservation
                            showCancelAlert = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.pageBg)
        .alert("Cancel Reservation", isPresented: $showCancelAlert) {
            Button("Keep", role: .cancel) {}
            Button("Cancel Reservation", role: .destructive) {
                if let r = selectedReservation {
                    r.status = .cancelled
                    try? modelContext.save()
                }
            }
        } message: {
            if let book = selectedReservation?.book {
                Text("Cancel reservation for \"\(book.title)\"?")
            }
        }
    }
}

// MARK: - Active Loan Card (premium)
struct ActiveLoanCard: View {
    let loan: Loan
    let user: AppUser
    let allLoans: [Loan]
    let onReturn: () -> Void

    @State private var animateProgress = false

    // Synthetic reading progress based on elapsed time since loan
    private var readingProgress: Double {
        guard loan.createdAt < loan.dueAt else { return 0 }
        let total = loan.dueAt.timeIntervalSince(loan.createdAt)
        let elapsed = Date().timeIntervalSince(loan.createdAt)
        return min(1.0, max(0, elapsed / total))
    }

    private var daysLeft: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: loan.dueAt).day ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // Book cover
                BookCoverThumb(url: loan.book?.coverUrl, size: CGSize(width: 60, height: 84))

                // Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(loan.book?.title ?? "Unknown Book")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    Text(loan.book?.author ?? "")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    // Due date badge
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2.weight(.semibold))
                        Text("Due: \(loan.dueAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(loan.isOverdue ? .red : .textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((loan.isOverdue ? Color.red : Color.purpleAccent).opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()

                // Progress %
                VStack(spacing: 2) {
                    Text("\(Int(readingProgress * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.purpleAccent)
                    if loan.isOverdue {
                        Text("OVERDUE")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    } else {
                        Text("\(daysLeft)d left")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purpleAccent.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: loan.isOverdue
                                    ? [.red, .orange]
                                    : [.purpleAccent, Color(hex: "A78BFA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateProgress ? geo.size.width * readingProgress : 0, height: 6)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: animateProgress)
                }
            }
            .frame(height: 6)

            // Action buttons
            HStack(spacing: 10) {
                Button(action: onReturn) {
                    Label("Return", systemImage: "arrowshape.turn.up.left.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color.pageBg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.divider, lineWidth: 1)
                        )
                }

                NavigationLink(destination: ReadingTrackerView(user: user, activeLoans: allLoans, preSelectedBook: loan.book)) {
                    Label("Continue", systemImage: "arrowtriangle.right.fill")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            LinearGradient(
                                colors: [.purpleAccent, Color(hex: "A78BFA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color.purpleAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.purpleAccent.opacity(0.08), radius: 12, x: 0, y: 4)
        .onAppear { animateProgress = true }
    }
}

// MARK: - History Session Card
struct HistorySessionCard: View {
    let session: ReadingSession

    private var pointsEarned: Int { (session.minutes / 10) * 10 }

    var body: some View {
        HStack(spacing: 14) {
            BookCoverThumb(url: session.book?.coverUrl, size: CGSize(width: 48, height: 68))

            VStack(alignment: .leading, spacing: 5) {
                Text(session.book?.title ?? "Unknown Book")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 10) {
                    Label("\(session.minutes) min", systemImage: "timer")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.purpleAccent)

                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(pointsEarned)")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(.amber)
                Text("pts")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.purpleAccent.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Reservation Card
struct ReservationCard: View {
    let reservation: Reservation
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            BookCoverThumb(url: reservation.book?.coverUrl, size: CGSize(width: 52, height: 74))

            VStack(alignment: .leading, spacing: 6) {
                Text(reservation.book?.title ?? "Unknown Book")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)

                Text(reservation.book?.author ?? "")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                HStack(spacing: 6) {
                    // Status pill
                    Text(reservation.status.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundColor(reservation.status == .approved ? .teal : .purpleAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            (reservation.status == .approved ? Color.teal : Color.purpleAccent)
                                .opacity(0.12)
                        )
                        .clipShape(Capsule())

                    Text(reservation.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(14)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.purpleAccent.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Shared Small Components

struct LibraryMiniStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: color.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

struct BookCoverThumb: View {
    let url: String?
    let size: CGSize

    var body: some View {
        Group {
            if let urlStr = url, let resolvedURL = URL(string: urlStr) {
                AsyncImage(url: resolvedURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private var fallbackView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purpleAccent.opacity(0.3), Color(hex: "A78BFA").opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "book.closed.fill")
                .font(.title3)
                .foregroundColor(.purpleAccent)
        }
    }
}

struct LibraryEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.purpleAccent.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purpleAccent, Color(hex: "A78BFA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

// Backwards-compatible shims so old references keep compiling
struct LibraryActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 50, height: 50)
                Image(systemName: icon).foregroundColor(color).font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundColor(.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(.textSecondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct LibraryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.title3)
                Spacer()
            }
            Text(value).font(.title2.weight(.bold)).foregroundColor(.textPrimary)
            Text(title).font(.caption).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }
}

struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.subheadline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium)).foregroundColor(.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(12)
    }
}
