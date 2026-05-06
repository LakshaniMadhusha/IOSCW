import SwiftUI

struct MemberTabView: View {
    let user: AppUser

    var body: some View {
        TabView {
            HomeView(user: user)
                .tabItem { Label("Home", systemImage: "house.fill") }

            DiscoverView(user: user)
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }

            LibraryView(user: user)
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            RewardsView()
                .tabItem { Label("Rewards", systemImage: "trophy.fill") }

            ProfileView(user: user)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(Color.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .environment(\.symbolVariants, .fill)
    }
}

