import SwiftUI
import SwiftData

struct HallsListView: View {
    @Query(sort: \Hall.floor) private var halls: [Hall]

    var body: some View {
        NavigationStack {
            List {
                ForEach(halls) { hall in
                    NavigationLink {
                        HallDetailView(hall: hall)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hall.name)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Text("Floor \(hall.floor) • \(hall.seats.count) seats")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Halls")
        }
    }
}

