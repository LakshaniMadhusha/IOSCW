import WidgetKit
import SwiftUI
import AppIntents
import MapKit

struct Provider: AppIntentTimelineProvider {
    private let appGroup = "group.com.smartlibrary.shared"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, points: 1250, minutes: 20, goal: 30, nextBookTitle: "The Great Gatsby", nextDueDate: Date().addingTimeInterval(86400 * 3), shelf: "A-12", reservationTitle: nil, reservationDate: nil, reservationLocation: nil)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, points: 1250, minutes: 20, goal: 30, nextBookTitle: "The Great Gatsby", nextDueDate: Date().addingTimeInterval(86400 * 3), shelf: "A-12", reservationTitle: nil, reservationDate: nil, reservationLocation: nil)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let defaults = UserDefaults(suiteName: appGroup)
        let streak = defaults?.integer(forKey: "readingStreak") ?? 0
        let points = defaults?.integer(forKey: "rewardPoints") ?? 0
        let minutes = defaults?.integer(forKey: "readingMinutes") ?? 0
        let goal = defaults?.integer(forKey: "readingGoal") ?? 30
        
        let bookTitle = defaults?.string(forKey: "nextBookTitle")
        let bookDueDateRaw = defaults?.double(forKey: "nextDueDate") ?? 0
        let bookDueDate = bookDueDateRaw > 0 ? Date(timeIntervalSince1970: bookDueDateRaw) : nil
        let bookShelf = defaults?.string(forKey: "nextBookShelf")
        
        let resTitle = defaults?.string(forKey: "nextReservationTitle")
        let resDateRaw = defaults?.double(forKey: "nextReservationDate") ?? 0
        let resDate = resDateRaw > 0 ? Date(timeIntervalSince1970: resDateRaw) : nil
        
        let resLat = defaults?.double(forKey: "nextReservationLat")
        let resLon = defaults?.double(forKey: "nextReservationLon")
        
        // Generate Map Snapshot if location exists
        var mapImage: UIImage? = nil
        if let lat = resLat, let lon = resLon, lat != 0 {
            mapImage = await generateMapSnapshot(lat: lat, lon: lon)
        }

        let entry = SimpleEntry(
            date: Date(),
            streak: streak,
            points: points,
            minutes: minutes,
            goal: goal,
            nextBookTitle: bookTitle,
            nextDueDate: bookDueDate,
            shelf: bookShelf,
            reservationTitle: resTitle,
            reservationDate: resDate,
            reservationLocation: mapImage
        )
        return Timeline(entries: [entry], policy: .atEnd)
    }
    
    private func generateMapSnapshot(lat: Double, lon: Double) async -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            latitudinalMeters: 400,
            longitudinalMeters: 400
        )
        options.size = CGSize(width: 200, height: 100)
        options.scale = 3.0
        
        let snapshotter = MKMapSnapshotter(options: options)
        return try? await withCheckedThrowingContinuation { continuation in
            snapshotter.start { snapshot, error in
                if let snapshot = snapshot {
                    continuation.resume(returning: snapshot.image)
                } else {
                    continuation.resume(throwing: error ?? NSError())
                }
            }
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let points: Int
    let minutes: Int
    let goal: Int
    let nextBookTitle: String?
    let nextDueDate: Date?
    let shelf: String?
    let reservationTitle: String?
    let reservationDate: Date?
    let reservationLocation: UIImage?
}

struct LibraryWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Streak & Points
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.streak)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("\(entry.points) pts")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.purple)
            }
            .padding(.bottom, 12)
            
            HStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.1), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(Double(entry.minutes) / Double(entry.goal), 1.0)))
                        .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.purple)
                }
                .frame(width: 36, height: 36)
                
                // Smart Content
                VStack(alignment: .leading, spacing: 2) {
                    if let bookTitle = entry.nextBookTitle, let dueDate = entry.nextDueDate {
                        HStack {
                            Text("DUE SOON")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.red.opacity(0.8))
                            
                            if let shelf = entry.shelf {
                                Text("SHELF \(shelf)")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(bookTitle)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        Text(dueDate, style: .relative)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    } else if let resTitle = entry.reservationTitle, let resDate = entry.reservationDate {
                        Text("UPCOMING")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.blue)
                        Text(resTitle)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        
                        if let mapImage = entry.reservationLocation {
                            Image(uiImage: mapImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 42)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.top, 4)
                        } else {
                            Text(resDate, style: .time)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("DAILY GOAL")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(.purple)
                        Text("\(entry.minutes)/\(entry.goal) mins")
                            .font(.system(size: 14, weight: .bold))
                        Text("Keep reading!")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                Color(UIColor.systemBackground)
                LinearGradient(colors: [Color.purple.opacity(0.08), .clear, Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
}

struct LibraryWidgets: Widget {
    let kind: String = "LibraryWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            LibraryWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Smart Library")
        .description("Your library dashboard with Shelf Assistant.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
