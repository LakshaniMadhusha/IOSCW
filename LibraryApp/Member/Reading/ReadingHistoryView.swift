import SwiftUI
import SwiftData

struct ReadingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [ReadingSession]
    @Query private var users: [AppUser]
    
    let userId: UUID
    
    @State private var pdfURL: URL?
    @State private var isGeneratingPDF = false
    
    var currentUser: AppUser? {
        users.first { $0.id == userId }
    }
    
    init(userId: UUID) {
        self.userId = userId
        let id = userId
        self._sessions = Query(
            filter: #Predicate<ReadingSession> { session in
                session.userId == id
            },
            sort: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        self._users = Query(filter: #Predicate<AppUser> { $0.id == id })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Reading History")
                            .font(.title3.weight(.bold))
                        Text("Start a reading session from your dashboard to begin tracking your journey.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 100)
                } else {
                    VStack(spacing: 0) {
                        historySummaryHeader
                        
                        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                            // Group sessions by day
                            let grouped = Dictionary(grouping: sessions) { session in
                                Calendar.current.startOfDay(for: session.startedAt)
                            }
                            let sortedDays = grouped.keys.sorted(by: >)
                            
                            ForEach(sortedDays, id: \.self) { day in
                                Section {
                                    VStack(spacing: 12) {
                                        ForEach(grouped[day]!) { session in
                                            HistoryRow(session: session)
                                        }
                                    }
                                } header: {
                                    Text(day.formatted(date: .complete, time: .omitted))
                                        .font(.subheadline.weight(.heavy))
                                        .foregroundColor(.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.pageBg)
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Reading Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.purple)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if let user = currentUser, !sessions.isEmpty {
                        Button {
                            generateAndSharePDF(user: user)
                        } label: {
                            if isGeneratingPDF {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.purple)
                            }
                        }
                        .disabled(isGeneratingPDF)
                    }
                }
            }
            .sheet(item: $pdfURL) { url in
                ActivityView(activityItems: [url])
            }
        }
    }
    
    private func generateAndSharePDF(user: AppUser) {
        isGeneratingPDF = true
        Task {
            if let url = PDFService.shared.generateReadingSummary(user: user, sessions: sessions) {
                self.pdfURL = url
            }
            isGeneratingPDF = false
        }
    }
    
    private var historySummaryHeader: some View {
        HStack(spacing: 20) {
            let totalPoints = sessions.reduce(0) { $0 + ($1.minutes / 10) + $1.challengeBonus }
            let totalQuizzes = sessions.filter { $0.challengeName?.contains("Quiz") == true }.count
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalPoints)")
                    .font(.title2.weight(.black))
                    .foregroundColor(.orange)
                Text("Total Points")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.cardBg)
            .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalQuizzes)")
                    .font(.title2.weight(.black))
                    .foregroundColor(.purple)
                Text("Quizzes Passed")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.cardBg)
            .cornerRadius(16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}



struct HistoryRow: View {
    let session: ReadingSession
    
    var body: some View {
        HStack(spacing: 16) {
            MiniCoverView(book: session.book)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.book?.title ?? "Unknown Activity")
                    .font(.headline)
                    .lineLimit(1)
                
                if let challenge = session.challengeName {
                    HStack(spacing: 4) {
                        Image(systemName: challenge.contains("Quiz") ? "checkmark.seal.fill" : "trophy.fill")
                            .font(.caption2)
                        Text(challenge)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(challenge.contains("Quiz") ? .purple : .orange)
                } else {
                    Text("Read for \(session.minutes) minutes")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Text(session.startedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Points earned
            let points = (session.minutes / 10) + session.challengeBonus
            if points > 0 {
                VStack(alignment: .trailing, spacing: 0) {
                    Text("+\(points)")
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundColor(.orange)
                    Text("Pts")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

fileprivate struct MiniCoverView: View {
    let book: Book?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                .frame(width: 50, height: 75)
            
            if let book = book, let urlString = book.coverUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 75)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.purple)
                    }
                }
            } else {
                Image(systemName: "book.closed.fill")
                    .foregroundColor(.purple)
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
