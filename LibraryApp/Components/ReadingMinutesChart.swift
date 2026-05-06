import SwiftUI
import Charts

struct ReadingMinutesChart: View {
    struct DayPoint: Identifiable {
        let id = UUID()
        let day: Date
        let minutes: Int
    }

    let sessions: [ReadingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reading minutes")
                .font(.headline)
                .foregroundColor(.textPrimary)

            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Minutes", point.minutes)
                )
                .foregroundStyle(Color.accent)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color.divider.opacity(0.8))
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.divider.opacity(0.8))
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color.cardBg)
        .cornerRadius(18)
    }

    private var points: [DayPoint] {
        let start = Calendar.current.date(byAdding: .day, value: -13, to: .now) ?? .now
        let days = (0..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }

        let grouped = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startedAt)
        }.mapValues { $0.reduce(0) { $0 + $1.minutes } }

        return days.map { day in
            DayPoint(day: day, minutes: grouped[Calendar.current.startOfDay(for: day)] ?? 0)
        }
    }
}

