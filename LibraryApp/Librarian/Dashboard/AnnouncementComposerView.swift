import SwiftUI
import SwiftData

struct AnnouncementComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var message = ""
    @State private var priority: AnnouncementPriority = .medium
    @State private var selectedIcon = "megaphone.fill"
    @State private var targetAudience: TargetAudience = .all
    @State private var sendLater = false
    @State private var scheduledDate = Date().addingTimeInterval(3600)
    
    @State private var isSending = false
    @State private var showSuccess = false
    
    let availableIcons = ["megaphone.fill", "star.fill", "exclamationmark.triangle.fill", "calendar.badge.plus", "book.closed.fill", "gift.fill", "bell.badge.fill", "info.circle.fill"]
    
    enum AnnouncementPriority: String, CaseIterable {
        case low = "General"
        case medium = "Important"
        case high = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    enum TargetAudience: String, CaseIterable {
        case all = "All Members"
        case students = "Students"
        case faculty = "Faculty"
        case overdue = "Overdue Users"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                if showSuccess {
                    SuccessOverlay(onComplete: { dismiss() })
                        .transition(.asymmetric(insertion: .scale, removal: .opacity))
                } else {
                    Form {
                        Section {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ANNOUNCEMENT TYPE")
                                    .font(.caption.weight(.black))
                                    .foregroundColor(.textSecondary)
                                    .tracking(1)
                                
                                Picker("Priority", selection: $priority) {
                                    ForEach(AnnouncementPriority.allCases, id: \.self) { p in
                                        Text(p.rawValue).tag(p)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SELECT ICON")
                                    .font(.caption.weight(.black))
                                    .foregroundColor(.textSecondary)
                                    .tracking(1)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(availableIcons, id: \.self) { icon in
                                            Button {
                                                selectedIcon = icon
                                                let generator = UISelectionFeedbackGenerator()
                                                generator.selectionChanged()
                                            } label: {
                                                Image(systemName: icon)
                                                    .font(.title3)
                                                    .frame(width: 44, height: 44)
                                                    .background(selectedIcon == icon ? priority.color : priority.color.opacity(0.1))
                                                    .foregroundColor(selectedIcon == icon ? .white : priority.color)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.cardBg)
                        
                        Section("Content") {
                            TextField("Headline", text: $title)
                                .font(.headline)
                            
                            TextEditor(text: $message)
                                .frame(minHeight: 100)
                                .overlay(alignment: .topLeading) {
                                    if message.isEmpty {
                                        Text("Write your message here...")
                                            .foregroundColor(.textSecondary.opacity(0.4))
                                            .padding(.top, 8)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                        .listRowBackground(Color.cardBg)
                        
                        Section("Delivery Options") {
                            Picker("Target Audience", selection: $targetAudience) {
                                ForEach(TargetAudience.allCases, id: \.self) { audience in
                                    Text(audience.rawValue).tag(audience)
                                }
                            }
                            
                            Toggle("Schedule for Later", isOn: $sendLater)
                                .tint(.purple)
                            
                            if sendLater {
                                DatePicker("Send At", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .listRowBackground(Color.cardBg)
                        
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("LIVE PREVIEW")
                                    .font(.caption.weight(.black))
                                    .foregroundColor(.textSecondary)
                                    .tracking(1)
                                
                                AnnouncementPreviewCard(
                                    title: title.isEmpty ? "Sample Headline" : title,
                                    message: message.isEmpty ? "Sample message content..." : message,
                                    priority: priority,
                                    icon: selectedIcon
                                )
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: sendAnnouncement) {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Broadcast")
                                .fontWeight(.bold)
                        }
                    }
                    .disabled(title.isEmpty || message.isEmpty || isSending)
                }
            }
        }
    }
    
    private func sendAnnouncement() {
        print("DEBUG: Initiating announcement broadcast...")
        isSending = true
        
        Task {
            // Simulated delay for premium feel
            try? await Task.sleep(for: .seconds(1.5))
            
            await MainActor.run {
                NotificationService.shared.scheduleLibrarianAnnouncement(
                    title: "[\(priority.rawValue)] \(title)",
                    message: message,
                    modelContext: modelContext
                )
                
                print("DEBUG: Announcement broadcasted successfully")
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                withAnimation(.spring()) {
                    isSending = false
                    showSuccess = true
                }
            }
        }
    }
}

// MARK: - Subcomponents

struct AnnouncementPreviewCard: View {
    let title: String
    let message: String
    let priority: AnnouncementComposerView.AnnouncementPriority
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(priority.color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(priority.color)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(priority.rawValue.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(priority.color)
                        .tracking(1)
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                Text("Now")
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
            }
            
            Text(message)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(priority.color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SuccessOverlay: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .symbolEffect(.bounce, options: .repeat(2))
            }
            
            VStack(spacing: 8) {
                Text("Blast Off!")
                    .font(.title.weight(.black))
                Text("Your announcement has been broadcasted to all library members.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onComplete) {
                Text("Done")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .cornerRadius(20)
            }
        }
    }
}
