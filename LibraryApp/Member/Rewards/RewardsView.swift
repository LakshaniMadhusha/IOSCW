import SwiftUI
import SwiftData
import Charts

struct RewardsView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingSession.startedAt, order: .reverse) private var sessions: [ReadingSession]
    @Query(sort: \Badge.earnedAt, order: .reverse) private var badges: [Badge]
    
    @State private var totalPoints: Int = 0
    @State private var showingRedeemSuccess = false
    @State private var selectedReward: String = ""
    @State private var chartSelection: Date? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // 1. Total Points Header Banner
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LOYALTY BALANCE")
                                .font(.caption.weight(.black))
                                .foregroundColor(.white.opacity(0.7))
                                .tracking(1)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(totalPoints)")
                                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .contentTransition(.numericText())
                                Text("Pts")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        Spacer()
                    }
                    .padding(24)
                    .background(
                        ZStack {
                            LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 200, height: 200)
                                .offset(x: 140, y: -40)
                        }
                    )
                    .cornerRadius(32)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // 2. Interactive Premium Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Velocity")
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 20)
                        
                        PremiumPointsChart(selection: $chartSelection)
                            .padding(20)
                            .background(Color.cardBg)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                            .padding(.horizontal, 20)
                    }

                    // 3. Reward Store
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Redeem Rewards")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("\(totalPoints) Available")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                RewardStoreCard(title: "Late Fee Waiver", icon: "ticket.fill", price: 500, color: .orange) { redeem("Late Fee Waiver", cost: 500) }
                                RewardStoreCard(title: "Priority Booking", icon: "calendar.badge.clock", price: 800, color: .blue) { redeem("Priority Booking", cost: 800) }
                                RewardStoreCard(title: "Courier Pass", icon: "box.truck.fill", price: 1200, color: .green) { redeem("Courier Pass", cost: 1200) }
                                RewardStoreCard(title: "Premium Badge", icon: "trophy.fill", price: 2000, color: .yellow) { redeem("Premium Badge", cost: 2000) }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // 4. Earn More Points (Suggestions)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Missions")
                            .font(.title3.weight(.bold))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            SuggestionRow(icon: "book.pages.fill", color: .blue, title: "Fiction Friday", points: "+150 Pts", subtitle: "Read 3 fiction books this week.")
                            SuggestionRow(icon: "star.bubble.fill", color: .orange, title: "The Critic", points: "+50 Pts", subtitle: "Review your last read book.")
                            SuggestionRow(icon: "flame.fill", color: .red, title: "Steady Reader", points: "+200 Pts", subtitle: "Maintain a 7-day reading streak.")
                        }
                        .padding(.horizontal, 20)
                    }

                    // 5. Badg es & Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Collection")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Button("Gallery") {}
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 20)

                        if badges.isEmpty {
                            EmptyBadgePlaceholder()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(badges.prefix(5)) { badge in
                                        BadgeCard(badge: badge)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.bottom, 20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Rewards")
            .onAppear(perform: calculatePoints)
            .sheet(isPresented: $showingRedeemSuccess) {
                RedemptionSuccessView(rewardName: selectedReward)
            }
        }
    }
    
    private func calculatePoints() {
        totalPoints = sessions.reduce(0) { $0 + ($1.minutes / 10) + $1.challengeBonus }
    }
    
    private func redeem(_ name: String, cost: Int) {
        guard totalPoints >= cost else { return }
        // In a real app, we would create a Transaction model here
        selectedReward = name
        totalPoints -= cost
        showingRedeemSuccess = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Subcomponents

struct PremiumPointsChart: View {
    @Binding var selection: Date?
    
    struct Point: Identifiable {
        let id = UUID()
        let day: Date
        let points: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("LAST 7 DAYS")
                .font(.caption2.weight(.bold))
                .foregroundColor(.textSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let selection {
                    Text("\(Int.random(in: 100...500))") // Real logic would use the selected point
                        .font(.title.weight(.bold))
                        .contentTransition(.numericText())
                    Text("Pts on \(selection.formatted(.dateTime.weekday()))")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                } else {
                    Text("1,240")
                        .font(.title.weight(.bold))
                    Text("Pts Total")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Chart {
                ForEach(points) { p in
                    AreaMark(
                        x: .value("Day", p.day, unit: .day),
                        y: .value("Points", p.points)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple.opacity(0.4), .purple.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Day", p.day, unit: .day),
                        y: .value("Points", p.points)
                    )
                    .foregroundStyle(Color.purple)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    if let selection, Calendar.current.isDate(selection, inSameDayAs: p.day) {
                        RuleMark(x: .value("Day", selection, unit: .day))
                            .foregroundStyle(Color.purple.opacity(0.2))
                            .offset(y: -10)
                        
                        PointMark(
                            x: .value("Day", p.day, unit: .day),
                            y: .value("Points", p.points)
                        )
                        .foregroundStyle(Color.purple)
                        .symbolSize(100)
                    }
                }
            }
            .frame(height: 180)
            .chartXSelection(value: $selection)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine().foregroundStyle(.clear)
                    AxisValueLabel(format: .dateTime.weekday(.short))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                }
            }
            .padding(.top, 16)
        }
    }

    private var points: [Point] {
        let start = Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now
        return (0..<7).compactMap { i in
            let day = Calendar.current.date(byAdding: .day, value: i, to: start) ?? .now
            return Point(day: day, points: Int.random(in: 120...420))
        }
    }
}

struct SuggestionRow: View {
    let icon: String
    let color: Color
    let title: String
    let points: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.15))
                .cornerRadius(14)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Spacer()
                    Text(points)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

struct RewardStoreCard: View {
    let title: String
    let icon: String
    let price: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(price)")
                        .font(.caption.weight(.black))
                        .foregroundColor(.textPrimary)
                    Text("Pts")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .frame(width: 140)
            .background(Color.cardBg)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
}

struct EmptyBadgePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "medal.fill")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))
            Text("Gallery Empty")
                .font(.headline)
            Text("Challenges yield unique badges.")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.cardBg)
        .cornerRadius(24)
        .padding(.horizontal, 20)
    }
}

struct RedemptionSuccessView: View {
    let rewardName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.purple.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .repeat(2))
                
                VStack(spacing: 8) {
                    Text("Redeemed!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Your \(rewardName) is active.")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Continue Reading")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(30)
                }
            }
        }
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "medal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            
            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(badge.earnedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(width: 110)
        .padding(.vertical, 16)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
