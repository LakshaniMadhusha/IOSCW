import SwiftUI

struct LibrarianTabView: View {
    let user: AppUser

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }

            MemberListView()
                .tabItem { Label("Members", systemImage: "person.2.fill") }

            BookManagementView()
                .tabItem { Label("Books", systemImage: "books.vertical.fill") }

            ReportedIssuesView()
                .tabItem { Label("Issues", systemImage: "exclamationmark.bubble.fill") }

            ProfileView(user: user)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .environment(\.symbolVariants, .fill)
    }
}

