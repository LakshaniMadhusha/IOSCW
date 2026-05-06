import SwiftUI
import SwiftData

struct MemberDetailView: View {
    let member: AppUser
    @Query private var sessions: [ReadingSession]
    @Query private var loans: [Loan]

    init(member: AppUser) {
        self.member = member
        let memberId = member.id
        _sessions = Query(filter: #Predicate<ReadingSession> { $0.userId == memberId }, sort: \ReadingSession.startedAt, order: .reverse)
        _loans = Query(filter: #Predicate<Loan> { $0.user?.id == memberId }, sort: \Loan.createdAt, order: .reverse)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // 1. Profile Header
                VStack(spacing: 16) {
                    ZStack {
                        if let data = member.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text(member.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                        Text(member.email)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(spacing: 12) {
                        DetailBadge(text: "Member", icon: "person.text.rectangle", color: .blue)
                        if member.membershipId != nil {
                            DetailBadge(text: "Verified", icon: "checkmark.seal.fill", color: .green)
                        }
                    }
                }
                .padding(.top, 10)
                
                // 2. Quick Actions
                HStack(spacing: 16) {
                    ActionCircleButton(icon: "envelope.fill", title: "Email") {
                        if let url = URL(string: "mailto:\(member.email)") { UIApplication.shared.open(url) }
                    }
                    ActionCircleButton(icon: "phone.fill", title: "Call") {
                        if let phone = member.phoneNumber, let url = URL(string: "tel:\(phone)") { UIApplication.shared.open(url) }
                    }
                    ActionCircleButton(icon: "message.fill", title: "SMS") {
                        if let phone = member.phoneNumber, let url = URL(string: "sms:\(phone)") { UIApplication.shared.open(url) }
                    }
                }
                
                // 3. Logistics Info
                VStack(alignment: .leading, spacing: 20) {
                    Text("Member Logistics")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 1) {
                        InfoRow(title: "Membership ID", value: member.membershipId ?? "Not Assigned", icon: "idcard")
                        InfoRow(title: "Phone", value: member.phoneNumber ?? "Not Provided", icon: "phone")
                        InfoRow(title: "Address", value: member.address ?? "Not Provided", icon: "mappin.and.ellipse")
                        InfoRow(title: "Joined", value: member.createdAt.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                    }
                    .background(Color.cardBg)
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                }
                
                // 4. Reading Activity
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reading Engagement")
                        .font(.headline)
                        .padding(.horizontal, 20)
                    
                    ReadingMinutesChart(sessions: sessions)
                        .frame(height: 200)
                        .padding(20)
                        .background(Color.cardBg)
                        .cornerRadius(24)
                        .padding(.horizontal, 20)
                }
                
                // 5. Active Loans
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Current Loans")
                            .font(.headline)
                        Spacer()
                        Text("\(loans.filter { $0.isActive }.count) Active")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 20)
                    
                    let activeLoans = loans.filter { $0.isActive }
                    if activeLoans.isEmpty {
                        Text("No active loans found.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(32)
                            .background(Color.cardBg)
                            .cornerRadius(24)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(activeLoans) { loan in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(loan.book?.title ?? "Unknown Book")
                                            .font(.subheadline.weight(.bold))
                                        Text("Due: \(loan.dueAt.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption)
                                            .foregroundColor(loan.isOverdue ? .red : .textSecondary)
                                    }
                                    Spacer()
                                    if loan.isOverdue {
                                        Text("Overdue")
                                            .font(.caption2.weight(.black))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(16)
                                .background(Color.cardBg)
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.bottom, 20)
        }
        .background(Color.pageBg.ignoresSafeArea())
        .navigationTitle("Member Profile")
    }
}

// MARK: - Subcomponents

struct DetailBadge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption.weight(.bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ActionCircleButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 54, height: 54)
                    .background(Color.cardBg)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.cardBg)
    }
}
