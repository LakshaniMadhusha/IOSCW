import SwiftUI
import SwiftData

struct MemberListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<AppUser> { $0.roleRaw == "Member" }, sort: \AppUser.name) private var members: [AppUser]
    
    @State private var searchText = ""
    @State private var selectedFilter: MemberFilter = .all
    
    enum MemberFilter: String, CaseIterable {
        case all = "All"
        case newest = "Newest"
        case active = "Active"
    }
    
    var filteredMembers: [AppUser] {
        var result = members
        
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch selectedFilter {
        case .all: break
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .active:
            // For now just sort by name since we don't have a specific "active" flag, but we could filter by recent loans
            break
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pageBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. KPI Header
                    HStack(spacing: 16) {
                        StatSmallCard(title: "Total Members", value: "\(members.count)", icon: "person.2.fill", color: .blue)
                        StatSmallCard(title: "New This Week", value: "\(members.filter { Calendar.current.isDate($0.createdAt, equalTo: .now, toGranularity: .weekOfYear) }.count)", icon: "sparkles", color: .purple)
                    }
                    .padding(20)
                    
                    // 2. Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MemberFilter.allCases, id: \.self) { filter in
                                FilterChip(title: filter.rawValue, isSelected: selectedFilter == filter) {
                                    withAnimation(.spring()) { selectedFilter = filter }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                    
                    // 3. Member Cards
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if filteredMembers.isEmpty {
                                EmptyStateView(icon: "person.slash.fill", title: "No members found", subtitle: "Try adjusting your search or filters.")
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredMembers) { member in
                                    NavigationLink {
                                        MemberDetailView(member: member)
                                    } label: {
                                        MemberRowCard(member: member)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Member Directory")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or email")
        }
    }
}

// MARK: - Subcomponents

struct StatSmallCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.textPrimary)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.cardBg)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.cardBg)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

struct MemberRowCard: View {
    let member: AppUser
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                if let data = member.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(LinearGradient(colors: [.purple.opacity(0.2), .indigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(String(member.name.prefix(1)).uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundColor(.purple)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.textSecondary.opacity(0.5))
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.3))
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
