import SwiftUI

struct ReportedIssuesView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    IssueCard(title: "Printer jam", detail: "Front desk • Reported 10m ago", severity: .amber)
                    IssueCard(title: "Overdue dispute", detail: "Member claims return • Reported 2h ago", severity: .coral)
                    IssueCard(title: "Seat sensor offline", detail: "Hall B • Reported yesterday", severity: .primary)
                }
                .padding(20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Issues")
        }
    }
}

private struct IssueCard: View {
    let title: String
    let detail: String
    let severity: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Circle()
                    .fill(severity)
                    .frame(width: 10, height: 10)
            }
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding(16)
        .lightCard()
    }
}

