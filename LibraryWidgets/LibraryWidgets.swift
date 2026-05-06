import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, nextBookTitle: "The Great Gatsby", nextDueDate: Date().addingTimeInterval(86400 * 3))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), streak: 5, nextBookTitle: "The Great Gatsby", nextDueDate: Date().addingTimeInterval(86400 * 3))
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Fetch real data from App Groups
        let defaults = UserDefaults(suiteName: "group.com.smartlibrary")
        let streak = defaults?.integer(forKey: "readingStreak") ?? 0
        let title = defaults?.string(forKey: "nextBookTitle")
        let dueDateRaw = defaults?.double(forKey: "nextDueDate") ?? 0
        let dueDate = dueDateRaw > 0 ? Date(timeIntervalSince1970: dueDateRaw) : nil

        let entry = SimpleEntry(date: Date(), streak: streak, nextBookTitle: title, nextDueDate: dueDate)
        return Timeline(entries: [entry], policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let nextBookTitle: String?
    let nextDueDate: Date?
}

struct LibraryWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "books.vertical.fill")
                    .foregroundColor(.purple)
                Text("Library")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Spacer()
                if entry.streak > 0 {
                    HStack(spacing: 2) {
                        Text("\(entry.streak)")
                            .font(.caption.weight(.heavy))
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            if let title = entry.nextBookTitle, let dueDate = entry.nextDueDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                        Text(dueDate, style: .relative)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.purple)
                }
            } else {
                Text("No books due")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
            LinearGradient(colors: [Color.purple.opacity(0.1), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}


struct LibraryWidgets: Widget {
    let kind: String = "LibraryWidgets"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            LibraryWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("My Library")
        .description("Track your reading streak and due dates.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
