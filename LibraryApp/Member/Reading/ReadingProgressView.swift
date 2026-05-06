import SwiftUI
import SwiftData
import Charts

struct ReadingProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [ReadingSession]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingGoalSetter = false
    @State private var dailyGoal: Int = 60 // minutes
    @State private var showingAchievements = false

    let user: AppUser

    init(user: AppUser) {
        self.user = user
        let userId = user.id
        self._sessions = Query(
            filter: #Predicate<ReadingSession> { $0.userId == userId },
            sort: [SortDescriptor(\.startedAt, order: .reverse)]
        )
    }

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Today's Progress Card
                    VStack(spacing: 16) {
                        Text("Today's Progress")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                                .frame(width: 200, height: 200)

                            Circle()
                                .trim(from: 0, to: min(1.0, Double(todayMinutes) / Double(dailyGoal)))
                                .stroke(
                                    LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 8) {
                                Text("\(todayMinutes)")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                Text("min")
                                    .font(.title3)
                                    .foregroundColor(.textSecondary)
                                Text("of \(dailyGoal) min goal")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .frame(height: 220)

                        if todayMinutes >= dailyGoal {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Goal achieved! 🎉")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Stats Grid
                    HStack(spacing: 16) {
                        StatCard(
                            title: "This \(selectedTimeRange.rawValue)",
                            value: "\(totalMinutesForRange()) min",
                            icon: "clock.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Sessions",
                            value: "\(sessionsForRange().count)",
                            icon: "book.pages.fill",
                            color: .purple
                        )
                        StatCard(
                            title: "Avg/Day",
                            value: "\(averageMinutesPerDay()) min",
                            icon: "chart.bar.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal, 20)

                    // Reading Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Activity")
                            .font(.title3.weight(.bold))

                        Chart(chartData(), id: \.date) { data in
                            BarMark(
                                x: .value("Date", data.date),
                                y: .value("Minutes", data.minutes)
                            )
                            .foregroundStyle(Color.purple.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .month)) { value in
                                AxisValueLabel(format: selectedTimeRange == .week ? .dateTime.day() : .dateTime.month())
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Recent Sessions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Sessions")
                            .font(.title3.weight(.bold))

                        if recentSessions().isEmpty {
                            Text("No recent reading sessions")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(recentSessions().prefix(5)) { session in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.book?.title ?? "Unknown Book")
                                            .font(.headline)
                                            .lineLimit(1)
                                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(session.minutes) min")
                                            .font(.headline)
                                            .foregroundColor(.purple)
                                        Text("+\(session.minutes / 10 * 10) pts")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                .padding(16)
                                .background(Color.surfaceBg)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)

                    // Reports & History
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reports & History")
                            .font(.title3.weight(.bold))
                        
                        NavigationLink(destination: ReadingHistoryView(userId: user.id)) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("View Reading Journey")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("See your detailed day-by-day activity")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color.surfaceBg)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            // This will open history where the PDF button is prominently displayed
                        } label: {
                            NavigationLink(destination: ReadingHistoryView(userId: user.id)) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title3)
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Generate PDF Summary")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Export a professional report of your data")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .background(Color.surfaceBg)
                                .cornerRadius(12)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Reading Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingGoalSetter = true }) {
                            Label("Set Daily Goal", systemImage: "target")
                        }
                        Button(action: { showingAchievements = true }) {
                            Label("Achievements", systemImage: "trophy.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingGoalSetter) {
                GoalSetterView(dailyGoal: $dailyGoal)
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView(user: user)
            }
        }
    }

    private var todayMinutes: Int {
        sessions.filter { Calendar.current.isDateInToday($0.startedAt) }
                .reduce(0) { $0 + $1.minutes }
    }

    private func totalMinutesForRange() -> Int {
        sessionsForRange().reduce(0) { $0 + $1.minutes }
    }

    private func sessionsForRange() -> [ReadingSession] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedTimeRange {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return sessions.filter { $0.startedAt >= startDate }
    }

    private func averageMinutesPerDay() -> Int {
        let totalMinutes = totalMinutesForRange()
        let days: Int

        switch selectedTimeRange {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }

        return days > 0 ? totalMinutes / days : 0
    }

    private func chartData() -> [(date: Date, minutes: Int)] {
        let calendar = Calendar.current
        let sessions = sessionsForRange()

        switch selectedTimeRange {
        case .week:
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let minutes = sessions.filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                                     .reduce(0) { $0 + $1.minutes }
                return (date: dayStart, minutes: minutes)
            }.reversed()

        case .month:
            return (0..<30).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
                let dayStart = calendar.startOfDay(for: date)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let minutes = sessions.filter { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
                                     .reduce(0) { $0 + $1.minutes }
                return (date: dayStart, minutes: minutes)
            }.reversed()

        case .year:
            return (0..<12).map { monthOffset in
                let date = calendar.date(byAdding: .month, value: -monthOffset, to: .now) ?? .now
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                let minutes = sessions.filter { $0.startedAt >= monthStart && $0.startedAt < monthEnd }
                                     .reduce(0) { $0 + $1.minutes }
                return (date: monthStart, minutes: minutes)
            }.reversed()
        }
    }

    private func recentSessions() -> [ReadingSession] {
        sessions.sorted { $0.startedAt > $1.startedAt }
    }
}

struct GoalSetterView: View {
    @Binding var dailyGoal: Int
    @Environment(\.dismiss) private var dismiss
    @State private var tempGoal: Int

    init(dailyGoal: Binding<Int>) {
        self._dailyGoal = dailyGoal
        self._tempGoal = State(initialValue: dailyGoal.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Set Daily Reading Goal")
                    .font(.title2.weight(.bold))

                VStack(spacing: 16) {
                    Text("\(tempGoal) minutes per day")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)

                    Slider(value: Binding(
                        get: { Double(tempGoal) },
                        set: { tempGoal = Int($0) }
                    ), in: 15...240, step: 15)
                    .tint(.purple)

                    HStack {
                        Text("15 min")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("4 hours")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                Button(action: {
                    dailyGoal = tempGoal
                    dismiss()
                }) {
                    Text("Save Goal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AchievementsView: View {
    let user: AppUser
    @Query private var badges: [Badge]
    @Query private var sessions: [ReadingSession]

    init(user: AppUser) {
        self.user = user
        let userId = user.id
        self._badges = Query(
            filter: #Predicate<Badge> { $0.user?.id == userId },
            sort: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        self._sessions = Query(
            filter: #Predicate<ReadingSession> { $0.userId == userId }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Text("Achievements")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Achievement Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Total Badges",
                            value: "\(badges.count)",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                        StatCard(
                            title: "Reading Streak",
                            value: "\(calculateStreak()) days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        StatCard(
                            title: "Books Read",
                            value: "\(uniqueBooksRead())",
                            icon: "book.closed.fill",
                            color: .blue
                        )
                    }

                    // Achievement Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Milestones")
                            .font(.title3.weight(.bold))

                        AchievementRow(
                            title: "First Session",
                            description: "Complete your first reading session",
                            isUnlocked: sessions.count > 0,
                            icon: "play.circle.fill"
                        )

                        AchievementRow(
                            title: "Bookworm",
                            description: "Read for 100 minutes in a day",
                            isUnlocked: sessions.contains { $0.minutes >= 100 },
                            icon: "ant.fill"
                        )

                        AchievementRow(
                            title: "Dedicated Reader",
                            description: "Maintain a 7-day reading streak",
                            isUnlocked: calculateStreak() >= 7,
                            icon: "flame.fill"
                        )

                        AchievementRow(
                            title: "Speed Reader",
                            description: "Read 5 books in a month",
                            isUnlocked: uniqueBooksRead() >= 5,
                            icon: "hare.fill"
                        )
                    }
                    .padding(20)
                    .background(Color.cardBg)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func calculateStreak() -> Int {
        if sessions.isEmpty { return 0 }

        let calendar = Calendar.current
        let sortedSessions = sessions.sorted { $0.startedAt > $1.startedAt }
        let uniqueDays = Set(sortedSessions.map { calendar.startOfDay(for: $0.startedAt) })
        let sortedDays = uniqueDays.sorted(by: >)

        if sortedDays.first.map({ !calendar.isDateInToday($0) }) ?? true { return 0 }

        var streak = 1
        for i in 1..<sortedDays.count {
            let expected = calendar.date(byAdding: .day, value: -i, to: sortedDays[0])!
            if sortedDays[i] == calendar.startOfDay(for: expected) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private func uniqueBooksRead() -> Int {
        Set(sessions.compactMap { $0.book?.id }).count
    }
}

struct AchievementRow: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .foregroundColor(isUnlocked ? .yellow : .secondary)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}