import SwiftUI
import SwiftData

struct HallDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedSeat: Seat?
    @State private var selectedEvent: HallEvent?
    @State private var showingConfirmation = false

    let hall: Hall

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                if !hall.events.isEmpty {
                    Text("Upcoming Hall Events")
                        .font(.headline)
                        .foregroundColor(.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(hall.events) { event in
                                Button {
                                    selectedEvent = event
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(event.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.textPrimary)
                                            .lineLimit(2)
                                        Text(event.date, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(16)
                                    .frame(width: 220, alignment: .leading)
                                    .background(selectedEvent?.id == event.id ? Color.accent.opacity(0.18) : Color.cardBg)
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(selectedEvent?.id == event.id ? Color.accent : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let event = selectedEvent {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event details")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textPrimary)

                            Text(event.eventDescription)
                                .font(.body)
                                .foregroundColor(.textSecondary)

                            HStack {
                                Label(hall.name, systemImage: "building.columns")
                                Spacer()
                                Text(event.date, format: Date.FormatStyle(date: .long, time: .shortened))
                            }
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        }
                        .padding(16)
                        .background(Color.cardBg)
                        .cornerRadius(18)
                    }

                    Divider()
                        .background(Color.divider)
                }

                Text("Select a seat")
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                SeatGridView(seats: hall.seats, selectedSeat: $selectedSeat) { seat in
                    selectedSeat = seat
                }

                Button {
                    showingConfirmation = true
                } label: {
                    Text(selectedSeat == nil ? "Select a seat" : "Reserve seat")
                }
                .buttonStyle(.primaryButton)
                .disabled(selectedSeat == nil || selectedSeat?.status != .available)
            }
            .padding(20)
        }
        .background(Color.pageBg.ignoresSafeArea())
        .navigationTitle(hall.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingConfirmation) {
            BiometricReservationConfirmationView(
                seatLabel: selectedSeat?.label ?? "",
                onConfirmAuthenticated: { reserveSelected() }
            )
        }
        .onAppear {
            if selectedEvent == nil {
                selectedEvent = hall.events.first
            }
        }
    }

    private func reserveSelected() {
        guard let selectedSeat else { return }
        selectedSeat.status = .reserved
        selectedSeat.reservedUntil = Calendar.current.date(byAdding: .hour, value: 2, to: .now)
        try? modelContext.save()

        // Schedule seat confirmation notification
        let reservation = Reservation(createdAt: .now, status: .approved)
        NotificationService.shared.scheduleSeatConfirmation(for: reservation, modelContext: modelContext)
    }
}

