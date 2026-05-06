import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.surfaceBg)
            .cornerRadius(14)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondaryButton: SecondaryButtonStyle { SecondaryButtonStyle() }
}

