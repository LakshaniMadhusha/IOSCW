import SwiftUI
import SwiftData
import MapKit
import CoreImage.CIFilterBuiltins

enum HallBookingTab: String, CaseIterable {
    case event = "Event"
    case seat = "Seat"
}

struct HallBookingView: View {
    @Query private var halls: [Hall]
    @Environment(\.modelContext) private var modelContext
    let user: AppUser

    @State private var selectedHall: Hall?
    @State private var selectedEvent: HallEvent?
    @State private var selectedSeat: Seat?
    @State private var selectedTab: HallBookingTab = .event
    @State private var bookingDate: Date = .now
    @State private var bookingHours = 2
    @State private var attendeeCount = 1
    @State private var showQRCode = false
    @State private var qrCodeImage: UIImage?
    @State private var qrCodeData: String?
    @State private var showBookingAlert = false
    @State private var bookingMessage = ""
    @State private var latestReservation: HallReservation?
    @State private var bookingReceiptURL: URL?
    @State private var isGeneratingReceipt = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325086),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private let qrContext = CIContext()
    private let qrFilter = CIFilter.qrCodeGenerator()

    var body: some View {
        ZStack {
            // Ambient Background
            LinearGradient(colors: [Color.pageBg, Color.purple.opacity(0.05), Color.pageBg], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hall Booking")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        Text("Reserve space for your reading events")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

                    Picker("Booking Type", selection: $selectedTab) {
                        ForEach(HallBookingTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    ZStack {
                        Map(coordinateRegion: $region, annotationItems: halls) { hall in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: hall.latitude, longitude: hall.longitude)) {
                                VStack(spacing: 4) {
                                    Image(systemName: selectedHall?.id == hall.id ? "mappin.circle.fill" : "mappin.circle")
                                        .font(.title2)
                                        .foregroundColor(selectedHall?.id == hall.id ? .purpleAccent : .red)
                                        .shadow(radius: 2)
                                        .onTapGesture {
                                            selectHall(hall)
                                        }
                                    Text(hall.name)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 250)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 24)

                    VStack(spacing: 20) {
                        if let selectedHall {
                            HallSummaryView(hall: selectedHall)
                        } else {
                            Text("Choose a library from the map or list below to start booking.")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .cornerRadius(22)
                                .padding(.horizontal, 24)
                        }

                        if selectedTab == .event {
                            EventBookingSection(
                                selectedHall: selectedHall,
                                selectedEvent: $selectedEvent,
                                bookingDate: $bookingDate,
                                attendeeCount: $attendeeCount,
                                actionTitle: "Reserve Event Spot",
                                onConfirm: createEventReservation
                            )
                            .padding(.horizontal, 24)
                        } else {
                            SeatBookingSection(
                                selectedHall: selectedHall,
                                selectedSeat: $selectedSeat,
                                bookingDate: $bookingDate,
                                bookingHours: $bookingHours,
                                attendeeCount: $attendeeCount,
                                actionTitle: "Reserve Seat",
                                onConfirm: createSeatReservation
                            )
                            .padding(.horizontal, 24)
                        }

                        HallListView(halls: halls, selectedHall: $selectedHall)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: halls) { _, newHalls in
            if selectedHall == nil, let first = newHalls.first {
                selectHall(first)
            }
        }
        .onAppear {
            if selectedHall == nil, let first = halls.first {
                selectHall(first)
            }
        }
        .alert("Booking Confirmed", isPresented: $showBookingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(bookingMessage)
        }
        .sheet(isPresented: $showQRCode) {
            QRCodeSheetView(
                user: user,
                reservation: latestReservation,
                image: qrCodeImage,
                isGenerating: $isGeneratingReceipt,
                receiptURL: $bookingReceiptURL
            )
        }
        .sheet(item: $bookingReceiptURL) { url in
            ActivityView(activityItems: [url])
        }
    }

    private func selectHall(_ hall: Hall) {
        selectedHall = hall
        selectedSeat = nil
        selectedEvent = hall.events.first
        region.center = CLLocationCoordinate2D(latitude: hall.latitude, longitude: hall.longitude)
    }

    private func createEventReservation() {
        guard let hall = selectedHall, let event = selectedEvent else { return }
        let payload = "type=event&hall=\(hall.name)&address=\(hall.address)&event=\(event.title)&date=\(event.date.iso8601String)&attendees=\(attendeeCount)"
        qrCodeImage = generateQRCode(from: payload)
        qrCodeData = base64String(from: qrCodeImage)

        let reservationDetails = event.title
        saveReservation(
            hallName: hall.name,
            hallAddress: hall.address,
            reservationType: .event,
            reservationDetails: reservationDetails,
            bookingDate: event.date,
            bookingHours: 0,
            attendeeCount: attendeeCount,
            qrCodeData: qrCodeData
        )

        NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: hall.name,
            hallAddress: hall.address,
            detailsDescription: "Your event reservation is now in Upcoming.",
            userId: user.id,
            modelContext: modelContext
        )
        bookingMessage = "Your event reservation has been confirmed and added to Upcoming."
        showBookingAlert = true
        showQRCode = true
    }

    private func createSeatReservation() {
        guard let hall = selectedHall, let seat = selectedSeat else { return }
        let payload = "type=seat&hall=\(hall.name)&address=\(hall.address)&seat=\(seat.label)&date=\(bookingDate.iso8601String)&hours=\(bookingHours)&attendees=\(attendeeCount)"
        qrCodeImage = generateQRCode(from: payload)
        qrCodeData = base64String(from: qrCodeImage)

        let reservationDetails = "Seat \(seat.label) for \(bookingHours) hr(s)"
        saveReservation(
            hallName: hall.name,
            hallAddress: hall.address,
            reservationType: .seat,
            reservationDetails: reservationDetails,
            bookingDate: bookingDate,
            bookingHours: bookingHours,
            attendeeCount: attendeeCount,
            qrCodeData: qrCodeData
        )

        if seat.status == .available {
            seat.status = .reserved
        }

        NotificationService.shared.scheduleHallBookingConfirmation(
            hallName: hall.name,
            hallAddress: hall.address,
            detailsDescription: "Your seat reservation is now in Upcoming.",
            userId: user.id,
            modelContext: modelContext
        )
        bookingMessage = "Your seat reservation has been confirmed and added to Upcoming."
        showBookingAlert = true
        showQRCode = true
    }

    private func saveReservation(
        hallName: String,
        hallAddress: String,
        reservationType: ReservationType,
        reservationDetails: String,
        bookingDate: Date,
        bookingHours: Int,
        attendeeCount: Int,
        qrCodeData: String?
    ) {
        let reservation = HallReservation(
            hallName: hallName,
            hallAddress: hallAddress,
            reservationType: reservationType,
            reservationDetails: reservationDetails,
            bookingDate: bookingDate,
            bookingHours: bookingHours,
            attendeeCount: attendeeCount,
            qrCodeData: qrCodeData,
            status: .confirmed,
            userId: user.id
        )
        modelContext.insert(reservation)
        latestReservation = reservation

        do {
            try modelContext.save()
            // Sync to Firebase Cloud
            FirebaseSyncService.shared.saveReservationToCloud(reservation)
        } catch {
            print("Failed to save hall reservation: \(error)")
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        qrFilter.message = Data(string.utf8)
        qrFilter.correctionLevel = "H"
        guard let output = qrFilter.outputImage,
              let cgImage = qrContext.createCGImage(output.transformed(by: CGAffineTransform(scaleX: 10, y: 10)), from: output.extent)
        else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func base64String(from image: UIImage?) -> String? {
        guard let image = image, let data = image.pngData() else {
            return nil
        }
        return data.base64EncodedString()
    }
}

private struct HallSummaryView: View {
    let hall: Hall

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hall.name)
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(hall.address)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Text("Floor \(hall.floor) • \(hall.seats.filter { $0.status == .available }.count) seats available")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBg)
        .cornerRadius(18)
    }
}

private struct EventBookingSection: View {
    let selectedHall: Hall?
    @Binding var selectedEvent: HallEvent?
    @Binding var bookingDate: Date
    @Binding var attendeeCount: Int
    let actionTitle: String
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Event Booking")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.textPrimary)

            if let selectedHall {
                Picker("Event", selection: $selectedEvent) {
                    ForEach(selectedHall.events) { event in
                        Text(event.title).tag(Optional(event))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.cardBg)
                .cornerRadius(16)

                DatePicker("Choose date and time", selection: $bookingDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .padding(14)
                    .background(Color.cardBg)
                    .cornerRadius(16)

                Stepper("Attendees: \(attendeeCount)", value: $attendeeCount, in: 1...4)
                    .padding(14)
                    .background(Color.cardBg)
                    .cornerRadius(16)

                Button(action: onConfirm) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryButton)
                .disabled(selectedEvent == nil)
            } else {
                Text("Select a library first.")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(Color.cardBg)
        .cornerRadius(18)
    }
}

private struct SeatBookingSection: View {
    let selectedHall: Hall?
    @Binding var selectedSeat: Seat?
    @Binding var bookingDate: Date
    @Binding var bookingHours: Int
    @Binding var attendeeCount: Int
    let actionTitle: String
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Seat Booking")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.textPrimary)

            if let selectedHall {
                SeatGridView(seats: selectedHall.seats, selectedSeat: $selectedSeat) { seat in
                    selectedSeat = seat
                }
                .frame(height: 280)

                DatePicker("Select date & time", selection: $bookingDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .padding(14)
                    .background(Color.cardBg)
                    .cornerRadius(16)

                Stepper("Reservation length: \(bookingHours) hrs", value: $bookingHours, in: 1...8)
                    .padding(14)
                    .background(Color.cardBg)
                    .cornerRadius(16)

                Stepper("Attendees: \(attendeeCount)", value: $attendeeCount, in: 1...4)
                    .padding(14)
                    .background(Color.cardBg)
                    .cornerRadius(16)

                Button(action: onConfirm) {
                    Text(actionTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryButton)
                .disabled(selectedSeat == nil)
            } else {
                Text("Choose a library first to reserve a seat.")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .background(Color.cardBg)
        .cornerRadius(18)
    }
}

private struct HallListView: View {
    let halls: [Hall]
    @Binding var selectedHall: Hall?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Libraries")
                .font(.headline)
                .foregroundColor(.textPrimary)

            ForEach(halls) { hall in
                Button {
                    selectedHall = hall
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hall.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textPrimary)
                            Text(hall.address)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Text("Floor \(hall.floor)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.purpleAccent)
                    }
                    .padding(14)
                    .background(selectedHall?.id == hall.id ? Color.accent.opacity(0.18) : Color.cardBg)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct QRCodeSheetView: View {
    let user: AppUser
    let reservation: HallReservation?
    let image: UIImage?
    @Binding var isGenerating: Bool
    @Binding var receiptURL: URL?

    var body: some View {
        VStack(spacing: 16) {
            Text("BOOKING CONFIRMED")
                .font(.headline.weight(.black))
                .foregroundColor(.purpleAccent)
            
            if let image {
                Image("CustomQR")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .padding()
                    .background(Color.cardBg)
                    .cornerRadius(24)
            }
            
            VStack(spacing: 8) {
                Text("Present this QR at the desk")
                    .font(.subheadline.weight(.semibold))
                Text("A copy has also been saved to your 'Upcoming' reservations.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            if let reservation {
                Button {
                    isGenerating = true
                    Task {
                        if let url = PDFService.shared.generateBookingReceipt(user: user, reservation: reservation) {
                            receiptURL = url
                        }
                        isGenerating = false
                    }
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "doc.text.fill")
                            Text("Download Receipt (PDF)")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purpleAccent)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(isGenerating)
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
        }
        .padding(24)
        .presentationDetents([.medium, .large])
    }
}

private extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
