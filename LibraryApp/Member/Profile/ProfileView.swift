import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    let user: AppUser
    
    @Query private var sessions: [ReadingSession]
    @Query private var allNotifications: [AppNotification]
    
    @State private var showingNotifications = false
    @State private var showingGoalSetter = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    @State private var booksReadCount: Int = 0
    @State private var totalPointsCount: Int = 0
    @State private var dayStreakCount: Int = 0
    @State private var unreadCount: Int = 0
    
    init(user: AppUser) {
        self.user = user
        let userId = user.id
        self._sessions = Query(
            filter: #Predicate<ReadingSession> { $0.userId == userId },
            sort: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        self._allNotifications = Query(
            filter: #Predicate<AppNotification> { $0.userId == userId || $0.userId == nil },
            sort: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }
    
    private func calculateStats() {
        // Run complex calculations on a background thread to keep UI responsive
        Task.detached(priority: .userInitiated) {
            let sessionData = sessions
            let notificationData = allNotifications
            let currentUserId = user.id
            
            // 1. unreadCount
            let unread = notificationData.filter { ($0.userId == currentUserId || $0.userId == nil) && !$0.isRead }.count
            
            // 2. booksRead
            let read = Set(sessionData.compactMap { $0.book?.id }).count
            
            // 3. totalPoints
            let points = sessionData.reduce(0) { $0 + ($1.minutes / 10) + $1.challengeBonus }
            
            // 4. dayStreak
            var streak = 0
            if !sessionData.isEmpty {
                let calendar = Calendar.current
                let uniqueDays = Set(sessionData.map { calendar.startOfDay(for: $0.startedAt) })
                let sortedDays = uniqueDays.sorted(by: >)
                
                if let firstDay = sortedDays.first, calendar.isDateInToday(firstDay) {
                    streak = 1
                    for i in 1..<sortedDays.count {
                        let expected = calendar.date(byAdding: .day, value: -i, to: sortedDays[0])!
                        if sortedDays[i] == expected { streak += 1 } else { break }
                    }
                }
            }
            
            await MainActor.run {
                self.unreadCount = unread
                self.booksReadCount = read
                self.totalPointsCount = points
                self.dayStreakCount = streak
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // 1. Header
                        headerView
                        
                        // 2. Membership Card
                        membershipCard
                        
                        if user.role == .librarian {
                            // Librarian Specific Sections
                            librarianStatsStrip
                            librarianDutyCard
                            librarianAdminLinks
                        } else {
                            // Member Specific Sections
                            statsStrip
                            courierStatusCard
                            earnedBadgesSection
                        }
                        
                        // 6. Support Block
                        supportQuickLinks
                        
                        // 7. Log Out Button (Main)
                        logOutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(userId: user.id)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(user: user)
            }
            .onAppear {
                calculateStats()
            }
            .onChange(of: sessions) { _, _ in calculateStats() }
            .onChange(of: allNotifications) { _, _ in calculateStats() }
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("My Library")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textSecondary)
                Text("Profile")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    showingNotifications = true
                } label: {
                    Image(systemName: "bell.badge.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(unreadCount > 0 ? .red : .clear, Color.textPrimary)
                        .font(.title3)
                }
                
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.textPrimary)
                        .font(.title3)
                }
                
                Button {
                    showingEditProfile = true
                } label: {
                    if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(user.name.prefix(1))
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
    }
    
    private var membershipCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Background with gradient and mesh-like overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .offset(x: 100, y: -50)
                    )
                
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: user.role == .librarian ? "shield.fill" : "sparkles")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                        Text(user.role == .librarian ? "LIBRARY STAFF" : "GOLD MEMBER")
                            .font(.caption.weight(.black))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(1)
                        Spacer()
                        Image(systemName: "applelogo")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name.uppercased())
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)
                            Text("ID: \(user.membershipId ?? "LIB-8845-102")")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        // QR Code Placeholder
                        Image(systemName: "qrcode")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
                .padding(24)
            }
            .frame(height: 200)
            .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 10)
            
            // New Bio Section
            if let bio = user.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ABOUT ME")
                        .font(.caption.weight(.black))
                        .foregroundColor(.textSecondary)
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(3)
                    
                    if let genre = user.favoriteGenre {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Favorite: \(genre)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardBg)
                .cornerRadius(20)
                .padding(.top, 12)
            }
        }
    }
    
    private var statsStrip: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(booksReadCount)", label: "Read", icon: "book.closed.fill", color: .blue)
            Divider().frame(height: 30).padding(.horizontal, 10)
            StatItem(value: "\(totalPointsCount)", label: "Points", icon: "star.fill", color: .orange)
            Divider().frame(height: 30).padding(.horizontal, 10)
            StatItem(value: "\(dayStreakCount)", label: "Streak", icon: "flame.fill", color: .red)
        }
        .padding(.vertical, 20)
        .background(Color.cardBg)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var earnedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Achievements")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("See All")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.purple)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ProfileBadgeCard(title: "Master", icon: "trophy.fill", iconColor: .yellow, desc: "50+ Books")
                    ProfileBadgeCard(title: "Runner", icon: "figure.run", iconColor: .green, desc: "7 Day Streak")
                    ProfileBadgeCard(title: "Explorer", icon: "map.fill", iconColor: .blue, desc: "5 Genres")
                    ProfileBadgeCard(title: "Social", icon: "person.2.fill", iconColor: .purple, desc: "3 Shared")
                }
            }
        }
    }
    
    private var courierStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COURIER LOGISTICS")
                .font(.caption.weight(.bold))
                .foregroundColor(.textSecondary)
                .padding(.leading, 12)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(totalPointsCount >= 100 ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: "truck.box.fill")
                        .foregroundColor(totalPointsCount >= 100 ? .green : .orange)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(totalPointsCount >= 100 ? "Ready for Dispatch" : "Pending Points")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text(totalPointsCount >= 100 ? "Next available slot: Today, 5 PM" : "Earn 100 points to unlock home delivery")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if totalPointsCount >= 100 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(16)
            .background(Color.cardBg)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(totalPointsCount >= 100 ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private var supportQuickLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK LINKS")
                .font(.caption.weight(.bold))
                .foregroundColor(.textSecondary)
                .padding(.leading, 12)
            
            VStack(spacing: 0) {
                NavigationLink(destination: Text("Library Rules")) {
                    SettingsNavigationRow(title: "Library Policies", icon: "book.fill", bgColor: .indigo)
                }
                Divider().background(Color.divider).padding(.leading, 56)
                
                NavigationLink(destination: Text("Support Chat")) {
                    SettingsNavigationRow(title: "Contact Support", icon: "message.fill", bgColor: .green)
                }
            }
            .background(Color.cardBg)
            .cornerRadius(16)
        }
    }
    
    private var logOutButton: some View {
        Button(action: { auth.signOut() }) {
            Text("Log Out")
                .font(.headline.weight(.bold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cardBg)
                .cornerRadius(16)
        }
    }
    
    // MARK: - Librarian Specific Components
    
    @Query private var allBooks: [Book]
    
    private var librarianStatsStrip: some View {
        HStack(spacing: 0) {
            StatItem(value: "\(allBooks.count)", label: "Cataloged", icon: "archivebox.fill", color: .purple)
            Divider().frame(height: 30).padding(.horizontal, 10)
            StatItem(value: "\(allNotifications.filter { $0.category == "announcement" }.count)", label: "Sent", icon: "megaphone.fill", color: .indigo)
            Divider().frame(height: 30).padding(.horizontal, 10)
            StatItem(value: "24/7", label: "Support", icon: "clock.badge.checkmark.fill", color: .green)
        }
        .padding(.vertical, 20)
        .background(Color.cardBg)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    @State private var isOnDuty = true
    private var librarianDutyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SHIFT STATUS")
                .font(.caption.weight(.bold))
                .foregroundColor(.textSecondary)
                .padding(.leading, 12)
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isOnDuty ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: isOnDuty ? "person.badge.shield.checkmark.fill" : "person.badge.minus.fill")
                        .foregroundColor(isOnDuty ? .green : .red)
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isOnDuty ? "Currently On-Duty" : "Off-Duty")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text(isOnDuty ? "Visible to members for support" : "Admin functions active only")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOnDuty)
                    .tint(.green)
                    .labelsHidden()
            }
            .padding(16)
            .background(Color.cardBg)
            .cornerRadius(20)
        }
    }
    
    private var librarianAdminLinks: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADMINISTRATIVE TOOLS")
                .font(.caption.weight(.bold))
                .foregroundColor(.textSecondary)
                .padding(.leading, 12)
            
            VStack(spacing: 0) {
                NavigationLink(destination: Text("System Settings")) {
                    SettingsNavigationRow(title: "Global Inventory Management", icon: "shippingbox.fill", bgColor: .purple)
                }
                Divider().background(Color.divider).padding(.leading, 56)
                
                NavigationLink(destination: Text("Member Analytics")) {
                    SettingsNavigationRow(title: "User Growth Insights", icon: "chart.line.uptrend.xyaxis", bgColor: .blue)
                }
            }
            .background(Color.cardBg)
            .cornerRadius(16)
        }
    }
}

// MARK: - Subcomponents

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileBadgeCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let desc: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.textPrimary)
                Text(desc)
                    .font(.system(size: 10).weight(.medium))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
        .frame(width: 130, height: 130, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(iconColor.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    let bgColor: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.caption)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsNavigationRow: View {
    let title: String
    let icon: String
    let bgColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(bgColor)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.caption)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.textSecondary)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let user: AppUser
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var membershipId: String = ""
    @State private var phoneNumber: String = ""
    @State private var address: String = ""
    @State private var occupation: String = ""
    @State private var bio: String = ""
    @State private var favoriteGenre: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                if let data = user.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(Image(systemName: "camera.fill").foregroundColor(.secondary))
                                }
                            }
                            Text("Change Photo")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.purple)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Membership & Delivery") {
                    TextField("Membership ID", text: $membershipId)
                    TextField("Home Address", text: $address, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("About Me") {
                    TextField("Occupation", text: $occupation)
                    TextField("Favorite Genre", text: $favoriteGenre)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            saveProfile()
                        }
                        .font(.headline)
                    }
                }
            }
            .alert("Save Error", isPresented: $showError, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage ?? "Unknown error occurred while saving profile.")
            })
            .onAppear {
                name = user.name
                email = user.email
                membershipId = user.membershipId ?? ""
                phoneNumber = user.phoneNumber ?? ""
                address = user.address ?? ""
                occupation = user.occupation ?? ""
                bio = user.bio ?? ""
                favoriteGenre = user.favoriteGenre ?? ""
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        // Compress image to ensure Firestore document size limits (1MB) are respected
                        if let uiImage = UIImage(data: data) {
                            let compressedData = uiImage.jpegData(compressionQuality: 0.3) // High compression for profile thumbs
                            user.profileImageData = compressedData ?? data
                            try? modelContext.save()
                            FirebaseSyncService.shared.updateUserInCloud(user)
                        }
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        user.name = name
        user.email = email
        user.membershipId = membershipId
        user.phoneNumber = phoneNumber
        user.address = address
        user.occupation = occupation
        user.bio = bio
        user.favoriteGenre = favoriteGenre
        
        do {
            try modelContext.save()
            
            // Push to Firebase
            FirebaseSyncService.shared.updateUserInCloud(user)
            
            // Give Firebase a moment to trigger the callback before dismissing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isSaving = false
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSaving = false
        }
    }
}
