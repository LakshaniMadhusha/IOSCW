import SwiftUI
import SwiftData

struct BookDetailView: View {
    let book: Book
    let user: AppUser?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedChallenge: String? = nil
    @State private var showingActionFeedback = false
    @State private var feedbackMessage = ""
    
    var body: some View {
        ZStack {
            Color.pageBg.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // ── Header Area ──────────────────────────────────────────
                    headerArea
                    
                    VStack(spacing: 24) {
                        // ── Title & Author ─────────────────────────────────────
                        VStack(spacing: 4) {
                            Text(book.title)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(book.author)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 20)
                        
                        // ── Stats Row ──────────────────────────────────────────
                        statsRow
                        
                        // ── Challenge Banner ───────────────────────────────────
                        if !book.getChallengeRelevance().isEmpty {
                            challengeBanner
                        }
                        
                        // ── Action Buttons ─────────────────────────────────────
                        actionButtons
                        
                        // ── Location & Info Cards ──────────────────────────────
                        VStack(spacing: 12) {
                            locationCard
                            queueCard
                        }
                        .padding(.top, 8)
                        
                        // ── Synopsis ───────────────────────────────────────────
                        synopsisSection
                        
                        // ── Details ────────────────────────────────────────────
                        detailsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            navigationControls
        }
        .overlay {
            if showingActionFeedback {
                feedbackOverlay
            }
        }
        .sheet(isPresented: Binding(
            get: { selectedChallenge != nil },
            set: { if !$0 { selectedChallenge = nil } }
        )) {
            if let challenge = selectedChallenge {
                ChallengeSessionView(challengeName: challenge, user: user, book: book)
            }
        }
    }
    
    // MARK: - Components
    
    private var headerArea: some View {
        ZStack {
            // Ambient Background Wash
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.pageBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)
            
            // Centered Cover
            AsyncImage(url: URL(string: book.coverUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.purpleAccent.opacity(0.3), radius: 20, x: 0, y: 15)
                default:
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purpleAccent)
                        Text(book.title)
                            .font(.caption)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(width: 180, height: 260)
                    .background(Color.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 60)
        }
    }
    
    private var navigationControls: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Button(action: { /* Share action */ }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            // Rating
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", book.rating))
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                }
                .foregroundColor(.orange)
                Text("Rating")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().background(Color.divider).frame(height: 20)
            
            // Genre
            VStack(spacing: 4) {
                Text(book.genre)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text("Genre")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider().background(Color.divider).frame(height: 20)
            
            // Availability Status
            VStack(spacing: 4) {
                if book.isAvailable {
                    Text("Available")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    Text("\(book.availableCopies) copies")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                } else {
                    Text("Waitlist")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textSecondary)
                    Text("\(book.totalCopies) copies")
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
    }
    
    private var challengeBanner: some View {
        Button(action: {
            if let first = book.getChallengeRelevance().first {
                selectedChallenge = first
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Matches your active monthly Challenge!")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.purple.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if book.isAvailable {
                Button(action: handleBorrow) {
                    Text("Borrow Book")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            } else {
                Button(action: handleReserve) {
                    Text("Reserve")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
            }
            
            Button(action: { /* Open Scanner */ }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 48)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            
            Button(action: {
                LiveActivityManager.shared.startPickupActivity(bookTitle: book.title, branch: book.branch)
                showFeedback(message: "Live Pickup Window Started!")
            }) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 48)
                    .background(Color.orange.opacity(0.6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var locationCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.branch)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text("Floor 2 Shelf \(book.shelfCode)")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Button(action: { /* Map view */ }) {
                Text("Find on Map")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }
    
    private var queueCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.2.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(book.waitingQueueCount) People in waiting queue")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text("Est. time: \(book.estimatedWaitTime)")
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(16)
    }
    
    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Synopsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text(book.summary)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                detailRow(label: "ISBN", value: "64546565675756")
                Divider().background(Color.divider)
                detailRow(label: "Pages", value: "304")
            }
            .padding(16)
            .background(Color.cardBg)
            .cornerRadius(16)
        }
        .padding(.top, 12)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Actions
    
    private func handleBorrow() {
        guard let user = user else { return }
        let loan = Loan(dueAt: Calendar.current.date(byAdding: .day, value: 14, to: .now)!)
        loan.user = user
        loan.book = book
        book.status = .onLoan
        modelContext.insert(loan)
        
        try? modelContext.save()
        
        showFeedback(message: "Borrowed Successfully!")
    }
    
    private func handleReserve() {
        guard let user = user else { return }
        let reservation = Reservation(status: .pending)
        reservation.user = user
        reservation.book = book
        book.status = .reserved
        modelContext.insert(reservation)
        
        try? modelContext.save()
        
        NotificationService.shared.scheduleBookReservationConfirmation(for: book.title, userId: user.id, modelContext: modelContext)
        showFeedback(message: "Reserved Successfully!")
    }
    
    private func showFeedback(message: String) {
        feedbackMessage = message
        withAnimation {
            showingActionFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingActionFeedback = false
            }
        }
    }
    
    private var feedbackOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(feedbackMessage)
                    .font(.headline)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(radius: 10)
            .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Supporting Views

private struct ChallengeSessionView: View {
    let challengeName: String
    let user: AppUser?
    let book: Book

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 60, height: 6)
                .padding(.top, 12)

            Text("Challenge Session")
                .font(.title2.weight(.bold))
                .padding(.top, 12)

            Text(challengeName)
                .font(.headline)
                .foregroundColor(.purple)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Complete this challenge to earn bonus points and get a boost toward your reading goals.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Button(action: handlePassChallenge) {
                Text("Mark Challenge Passed")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(user == nil ? Color.gray.opacity(0.5) : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .disabled(user == nil)

            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cardBg)
                    .foregroundColor(.textPrimary)
                    .cornerRadius(16)
            }
        }
        .padding(24)
    }

    private func handlePassChallenge() {
        guard let user = user else { return }
        let session = ReadingSession(minutes: 0, userId: user.id, challengeName: challengeName, challengeBonus: 100)
        session.user = user
        session.book = book
        modelContext.insert(session)
        try? modelContext.save()
        dismiss()
    }
}
