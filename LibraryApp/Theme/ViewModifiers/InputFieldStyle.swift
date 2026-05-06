import SwiftUI

private struct InputModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.surfaceBg)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.accent : Color.clear, lineWidth: 1.5)
            )
            .focused($isFocused)
    }
}

extension View {
    func inputStyle() -> some View {
        modifier(InputModifier())
    }
}

