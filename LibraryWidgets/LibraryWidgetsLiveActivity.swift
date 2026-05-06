import ActivityKit
import WidgetKit
import SwiftUI

struct LibraryActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var message: String
        var progress: Double // 0.0 to 1.0
        var endTime: Date?
    }
    
    var title: String
    var activityType: String // "pickup", "booking", "dueReminder"
}

struct LibraryWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LibraryActivityAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 45, height: 45)
                        Circle()
                            .trim(from: 0, to: context.state.progress)
                            .stroke(activityColor(for: context.attributes.activityType), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 45, height: 45)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: activityIcon(for: context.attributes.activityType))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(activityColor(for: context.attributes.activityType))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.state.message)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if let endTime = context.state.endTime {
                        VStack(alignment: .trailing) {
                            Text("Ends at")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            Text(endTime, style: .timer)
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
            .activityBackgroundTint(Color(white: 0.1))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: activityIcon(for: context.attributes.activityType))
                        .font(.title2)
                        .foregroundColor(activityColor(for: context.attributes.activityType))
                        .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let endTime = context.state.endTime {
                        VStack(alignment: .trailing) {
                            Text("TIME LEFT")
                                .font(.caption2.weight(.black))
                                .foregroundColor(.gray)
                            Text(endTime, style: .timer)
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundColor(activityColor(for: context.attributes.activityType))
                        }
                        .padding(.trailing, 8)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(context.state.message)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(context.state.progress * 100))%")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.gray)
                        }
                        
                        ProgressView(value: context.state.progress)
                            .tint(activityColor(for: context.attributes.activityType))
                            .background(Color.white.opacity(0.1))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            } compactLeading: {
                Image(systemName: activityIcon(for: context.attributes.activityType))
                    .foregroundColor(activityColor(for: context.attributes.activityType))
            } compactTrailing: {
                if let endTime = context.state.endTime {
                    Text(endTime, style: .timer)
                        .monospacedDigit()
                        .frame(width: 45)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(activityColor(for: context.attributes.activityType))
                }
            } minimal: {
                Image(systemName: activityIcon(for: context.attributes.activityType))
                    .foregroundColor(activityColor(for: context.attributes.activityType))
            }
            .widgetURL(URL(string: "smartlibrary://activity/\(context.attributes.activityType)"))
            .keylineTint(activityColor(for: context.attributes.activityType))
        }
    }
    
    // Helpers
    private func activityColor(for type: String) -> Color {
        switch type {
        case "pickup": return .green
        case "booking": return .orange
        case "dueReminder": return .red
        default: return .blue
        }
    }
    
    private func activityIcon(for type: String) -> String {
        switch type {
        case "pickup": return "shippingbox.fill"
        case "booking": return "clock.fill"
        case "dueReminder": return "exclamationmark.triangle.fill"
        default: return "book.fill"
        }
    }
}

#Preview("Pickup", as: .content, using: LibraryActivityAttributes(title: "Book Ready", activityType: "pickup")) {
   LibraryWidgetsLiveActivity()
} contentStates: {
    LibraryActivityAttributes.ContentState(status: "Ready", message: "Collect from Main Branch", progress: 0.7, endTime: Date().addingTimeInterval(3600))
}

#Preview("Booking", as: .content, using: LibraryActivityAttributes(title: "Hall Booking", activityType: "booking")) {
   LibraryWidgetsLiveActivity()
} contentStates: {
    LibraryActivityAttributes.ContentState(status: "Active", message: "Quiet Study Area", progress: 0.3, endTime: Date().addingTimeInterval(1800))
}
