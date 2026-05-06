import SwiftUI

struct LightCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBg)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
    }
}

extension View {
    func lightCard() -> some View {
        modifier(LightCardModifier())
    }
}

