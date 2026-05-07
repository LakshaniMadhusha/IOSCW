import SwiftUI
import SwiftData

struct ReadingTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let user: AppUser
    let activeLoans: [Loan]
    
    @State private var selectedBook: Book?
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var timerTask: Task<Void, Never>?
    @State private var lastTickDate = Date()
    @State private var showSuccess = false
    @State private var targetMinutes: Double = 15
    @State private var isManualMode = false
    @State private var manualDate = Date()
    @State private var manualMinutes: Int = 30
    
    // Integrated Reader Features
    @State private var isReadingMode = false
    @State private var targetReached = false
    @State private var showingQuiz = false
    @State private var isBookFinished = false
    
    // New Challenge Feature
    @State private var isChallengeMode = false
    @State private var challengeDuration = 5 // Fixed 5 mins for the challenge
    @State private var challengeWon = false
    @State private var courierPassURL: URL?
    @State private var bellRung = false
    @State private var bellAnimation = false
    @AppStorage("showDebugLabels") private var showDebugLabels = false
    
    init(user: AppUser, activeLoans: [Loan], preSelectedBook: Book? = nil) {
        self.user = user
        self.activeLoans = activeLoans
        self._selectedBook = State(initialValue: preSelectedBook)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isReadingMode, let url = URL(string: selectedBook?.pdfUrl ?? "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf") {
                    // Reader Mode UI (PDF Viewer) - NO ScrollView here to prevent gesture conflicts
                    AccessiblePDFReader(url: url)
                        .edgesIgnoringSafeArea(.bottom)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Tracker UI with ScrollView for responsiveness
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            Picker("Tracking Mode", selection: $isManualMode) {
                                Text("Live Timer").tag(false)
                                Text("Manual Log").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            // Book Selection
                            if activeLoans.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "books.vertical.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textSecondary)
                                    Text("No active loans.")
                                        .font(.headline)
                                    Text("Borrow a book to start tracking your reading.")
                                        .font(.subheadline)
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.cardBg)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What are you reading?")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.textSecondary)
                                        .padding(.horizontal, 24)
                                    
                                    Picker("Select Book", selection: $selectedBook) {
                                        Text("Select a book...").tag(Book?.none)
                                        ForEach(activeLoans.compactMap { $0.book }) { book in
                                            Text(book.title).tag(Book?.some(book))
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.cardBg)
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                }
                                
                                // 4. Challenge Mode Card
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Home Courier Challenge")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("Read for \(challengeDuration) mins to unlock Home Borrowing")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Spacer()
                                        Toggle("", isOn: $isChallengeMode)
                                            .tint(Color.accent)
                                            .labelsHidden()
                                            .onChange(of: isChallengeMode) { _, newValue in
                                                if newValue {
                                                    targetMinutes = Double(challengeDuration)
                                                    isManualMode = false
                                                }
                                            }
                                    }
                                    
                                    if isChallengeMode {
                                        HStack {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundColor(.green)
                                            Text("Live Activity enabled on Lock Screen")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(24)
                                .padding(.horizontal, 20)
                                .opacity(isManualMode ? 0.5 : 1.0)
                                .disabled(isManualMode)
                                
                                if !isManualMode {
                                    // Target Selection
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("Reading Target")
                                                .font(.subheadline.weight(.medium))
                                                .foregroundColor(.textSecondary)
                                            Spacer()
                                            Text("\(Int(targetMinutes)) min")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundColor(.purple)
                                        }
                                        .padding(.horizontal, 24)
                                        
                                        Slider(value: $targetMinutes, in: 5...120, step: 5)
                                            .tint(.purple)
                                            .padding(.horizontal, 24)
                                            .accessibilityLabel("Target Reading Minutes")
                                            .accessibilityValue("\(Int(targetMinutes)) minutes")
                                    }
                                }
                            }
                            
                            if !isManualMode {
                                // Clock Area
                                ZStack {
                                    Circle()
                                        .stroke(
                                            LinearGradient(colors: [.purple.opacity(0.2), .indigo.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 24
                                        )
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(min(1.0, timeElapsed / (targetMinutes * 60))))
                                        .stroke(
                                            LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom),
                                            style: StrokeStyle(lineWidth: 24, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .animation(.linear(duration: 1.0), value: timeElapsed)
                                    
                                    VStack {
                                        let minutes = Int(timeElapsed) / 60
                                        let seconds = Int(timeElapsed) % 60
                                        Text("\(minutes):\(String(format: "%02d", seconds))")
                                            .font(.system(size: 64, weight: .bold, design: .rounded))
                                            .foregroundColor(.textPrimary)
                                            .contentTransition(.numericText())
                                            .accessibilityLabel("Current Reading Time")
                                            .accessibilityValue("\(minutes) minutes and \(seconds) seconds")
                                        Text("Minutes Read")
                                            .font(.headline)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Reading Session Timer")
                                .accessibilityValue("\(Int(timeElapsed / 60)) minutes read out of \(Int(targetMinutes)) targeted")
                                .frame(width: 280, height: 280)
                                .padding(.top, 20)
                                .overlay(alignment: .bottom) {
                                    if showDebugLabels {
                                        Text("VO: \(Int(timeElapsed / 60))m read of \(Int(targetMinutes))m")
                                            .font(.caption2.monospaced())
                                            .padding(4)
                                            .background(.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                            .offset(y: 20)
                                    }
                                }
                                
                                Spacer()
                                
                                // Controls
                                if selectedBook != nil || timeElapsed > 0 || !activeLoans.isEmpty {
                                    HStack(spacing: 20) {
                                        if !isRunning && timeElapsed == 0 {
                                            Button(action: startTimer) {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white)
                                                    .frame(width: 80, height: 80)
                                                    .background(LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom))
                                                    .clipShape(Circle())
                                                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                                            }
                                        } else {
                                            Button(action: isRunning ? pauseTimer : startTimer) {
                                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.white)
                                                    .frame(width: 80, height: 80)
                                                    .background(isRunning ? Color.orange : Color.green)
                                                    .clipShape(Circle())
                                                    .shadow(color: (isRunning ? Color.orange : Color.green).opacity(0.4), radius: 10, x: 0, y: 5)
                                            }
                                            
                                            Button(action: saveSession) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 32, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 80, height: 80)
                                                    .background(Color.purple)
                                                    .clipShape(Circle())
                                                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                                            }
                                            .accessibilityLabel("Save Session")
                                            .accessibilityHint("Saves your current reading progress to your history.")
                                        }
                                    }
                                    .padding(.bottom, 40)
                                    .overlay(alignment: .top) {
                                        if showDebugLabels {
                                            Text("HINT: Tap to Save Session")
                                                .font(.system(size: 8).monospaced())
                                                .padding(4)
                                                .background(.purple.opacity(0.8))
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                                .offset(y: -20)
                                        }
                                    }
                                }
                            } else {
                                // Manual Log Area
                                VStack(spacing: 32) {
                                    DatePicker("Date Read", selection: $manualDate, in: ...Date(), displayedComponents: .date)
                                        .font(.headline)
                                        .padding(.horizontal, 24)
                                    
                                    Stepper("Time Read: \(manualMinutes) mins", value: $manualMinutes, in: 1...600, step: 5)
                                        .font(.headline)
                                        .padding(.horizontal, 24)
                                    
                                    Button(action: saveManualSession) {
                                        Text("Save Entry")
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
                                    .padding(.horizontal, 24)
                                    .padding(.top, 24)
                                }
                                .padding(.top, 40)
                                
                                Spacer()
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Reading Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(showDebugLabels ? "Hide Labels" : "Debug A11y") {
                        showDebugLabels.toggle()
                    }
                    .font(.caption2)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        pauseTimer()
                        dismiss()
                    }
                    .foregroundColor(.purple)
                }
            }
            .overlay {
                if showSuccess {
                    successOverlay
                }
            }
            .sheet(isPresented: $showingQuiz) {
                if let book = selectedBook {
                    ReadingVerificationQuizView(book: book, user: user)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Reader Toggle Button
                if !isManualMode && selectedBook != nil {
                    Button(action: { withAnimation(.spring()) { isReadingMode.toggle() }}) {
                        HStack(spacing: 8) {
                            Image(systemName: isReadingMode ? "clock.fill" : "book.pages.fill")
                            Text(isReadingMode ? "Focus Mode" : "Reader Mode")
                                .font(.subheadline.weight(.bold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.purpleAccent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(24)
                    .padding(.bottom, isReadingMode ? 40 : 0)
                }
            }
            .overlay(alignment: .top) {
                // Floating Timer for Reader Mode
                if isReadingMode {
                    HStack(spacing: 12) {
                        Image(systemName: "timer")
                            .foregroundColor(.purpleAccent)
                        
                        let minutes = Int(timeElapsed) / 60
                        let seconds = Int(timeElapsed) % 60
                        Text("\(minutes):\(String(format: "%02d", seconds))")
                            .font(.system(.body, design: .rounded).weight(.bold))
                        
                        Divider().frame(height: 16)
                        
                        Text("\(Int(targetMinutes))m Target")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.purpleAccent.opacity(0.2), lineWidth: 1))
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            if selectedBook != nil && !isRunning {
                startTimer()
            }
        }
        .onDisappear {
            pauseTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        lastTickDate = Date()
        
        // Start Live Activity if in challenge mode
        if isChallengeMode {
            LiveActivityManager.shared.startReadingChallengeActivity(
                bookTitle: selectedBook?.title ?? "a book",
                durationMinutes: challengeDuration
            )
        }
        
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                let now = Date()
                let elapsedSinceTick = now.timeIntervalSince(lastTickDate)
                lastTickDate = now
                withAnimation(.linear(duration: 1.0)) {
                    timeElapsed += elapsedSinceTick
                }
                
                // Auto-award points on target completion
                if !targetReached && timeElapsed >= (targetMinutes * 60) {
                    targetReached = true
                    Task { @MainActor in
                        triggerTargetReachedSuccess()
                    }
                }
            }
        }
    }
    
    private func triggerTargetReachedSuccess() {
        // Auto-save a milestone session
        let session = ReadingSession(minutes: Int(targetMinutes), userId: user.id)
        session.book = selectedBook
        session.challengeName = "Daily Goal Reached"
        session.challengeBonus = 50
        modelContext.insert(session)
        try? modelContext.save()
        
        triggerSuccess()
    }
    
    // MARK: - Helpers
    
    private func pauseTimer() {
        isRunning = false
        LiveActivityManager.shared.endAllActivities()
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func saveSession() {
        pauseTimer()
        let minutes = max(1, Int(timeElapsed) / 60)
        
        // End Live Activity
        LiveActivityManager.shared.endAllActivities()
        
        let challengeName = isChallengeMode && targetReached ? "Home Courier Challenge" : nil
        let bonus = isChallengeMode && targetReached ? 50 : 0
        
        if challengeName != nil {
            challengeWon = true
        }
        
        let session = ReadingSession(minutes: minutes, userId: user.id, challengeName: challengeName, challengeBonus: bonus)
        session.book = selectedBook
        modelContext.insert(session)
        try? modelContext.save()
        
        // Schedule challenge milestone notification
        NotificationService.shared.scheduleChallengeMilestone(userId: user.id, milestone: challengeName != nil ? "Unlocked Home Borrowing!" : "Read for \(minutes) minutes!", modelContext: modelContext)
        
        triggerSuccess()
    }
    
    private func saveManualSession() {
        let session = ReadingSession(startedAt: manualDate, minutes: manualMinutes, userId: user.id)
        session.book = selectedBook
        modelContext.insert(session)
        try? modelContext.save()
        
        triggerSuccess()
    }
    
    private func triggerSuccess() {
        withAnimation(.spring()) {
            showSuccess = true
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.1).ignoresSafeArea()
            Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
            
            VStack(spacing: 32) {
                if challengeWon {
                    // Elite Challenge Success View
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                .frame(width: 120, height: 120)
                                .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(showSuccess ? 1 : 0.5)
                        .opacity(showSuccess ? 1 : 0)
                        
                        VStack(spacing: 8) {
                            Text("CHALLENGE PASSED")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            Text("HOME DELIVERY UNLOCKED")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                                .tracking(1)
                        }
                        
                        Text("Your book \"\(selectedBook?.title ?? "this book")\" is now scheduled for home dispatch!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Courier Interaction Hub
                        HStack(spacing: 16) {
                            Button {
                                triggerHaptic(.heavy)
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                                    bellAnimation = true
                                    bellRung = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    bellAnimation = false
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: bellRung ? "bell.fill" : "bell")
                                        .font(.title2)
                                        .scaleEffect(bellAnimation ? 1.4 : 1.0)
                                    Text(bellRung ? "Notified" : "Notify")
                                        .font(.caption.weight(.bold))
                                }
                                .frame(width: 90, height: 80)
                                .background(bellRung ? Color.green : Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            
                            Button {
                                if let book = selectedBook {
                                    let pts = max(1, Int(timeElapsed) / 60 / 10) + 50
                                    courierPassURL = PDFService.shared.generateCourierReceipt(user: user, book: book, points: pts)
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                    Text("Pass")
                                        .font(.caption.weight(.bold))
                                }
                                .frame(width: 90, height: 80)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                        }
                    }
                } else {
                    // Premium Standard Session Success
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 140, height: 140)
                            
                            Circle()
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                .frame(width: 160, height: 160)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 90))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .green)
                                .shadow(color: .green.opacity(0.3), radius: 15, x: 0, y: 8)
                        }
                        .scaleEffect(showSuccess ? 1 : 0.8)
                        .opacity(showSuccess ? 1 : 0)
                        
                        VStack(spacing: 12) {
                            Text("Session Saved!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.textPrimary)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("+\(max(1, Int(timeElapsed) / 60 / 10) + (challengeWon ? 50 : 0)) Points Gained")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                
                // Action Stack
                VStack(spacing: 16) {
                    if !isBookFinished && selectedBook != nil {
                        Button {
                            triggerHaptic(.medium)
                            isBookFinished = true
                            showingQuiz = true
                        } label: {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.headline)
                                Text("Verify with Quiz")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(20)
                            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    
                    Button {
                        triggerHaptic(.light)
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.cardBg)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.divider, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color.cardBg)
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 20)
            )
            .padding(24)
            .sheet(item: $courierPassURL) { url in
                ActivityView(activityItems: [url])
            }
        }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
