import SwiftUI

struct StatusPill: View {
    let status: BookStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(bgColor)
            .clipShape(Capsule())
    }

    private var bgColor: Color {
        switch status {
        case .available: return Color.teal.opacity(0.15)
        case .reserved: return Color.amber.opacity(0.18)
        case .onLoan: return Color.coral.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch status {
        case .available: return .teal
        case .reserved: return .amber
        case .onLoan: return .coral
        }
    }
}

