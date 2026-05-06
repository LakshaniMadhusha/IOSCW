import SwiftUI

struct SeatGridView: View {
    let seats: [Seat]
    @Binding var selectedSeat: Seat?
    var onTap: (Seat) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 8)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(seats) { seat in
                Button {
                    onTap(seat)
                } label: {
                    Text(seat.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(color(for: seat))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedSeat?.id == seat.id ? Color.accent : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .disabled(seat.status != .available)
            }
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(18)
    }

    private func color(for seat: Seat) -> Color {
        switch seat.status {
        case .available: return Color.teal.opacity(0.18)
        case .occupied: return Color.divider.opacity(0.8)
        case .reserved: return Color.amber.opacity(0.22)
        }
    }
}

