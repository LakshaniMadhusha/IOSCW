import SwiftUI

extension Color {
    // Dynamic Colors for perfect iOS support
    static let pageBg = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: "1E1E1E")) : UIColor(Color(hex: "F7F5FF"))
    })

    static let cardBg = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: "29292A")) : UIColor(Color(hex: "FFFFFF"))
    })

    static let surfaceBg = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: "343436")) : UIColor(Color(hex: "EEF0FB"))
    })

    static let accent = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor(Color(hex: "8166FF")) : UIColor(Color(hex: "6C63FF"))
    }) // Replaces custom `.primary` to avoid Apple's `.primary` text color conflicts

    // ── Library Feature: Light Purple Theme ──────────────────────────────
    /// Soft light-purple used for the Library section background.
    static let lightPurpleBg = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "231B3A"))
            : UIColor(Color(hex: "EDE8FF"))
    })

    /// Card surface inside the Library (slightly lighter/darker than bg).
    static let lightPurpleCard = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(Color(hex: "2E2450"))
            : UIColor(Color(hex: "F8F5FF"))
    })

    /// Vivid purple accent pulled from the theme — use for highlights/pills.
    static let purpleAccent = Color(hex: "7C5CFF")
    // ─────────────────────────────────────────────────────────────────────

    // Explicit Dark mappings for compatibility with older code while refactoring
    static let darkPrimary       = Color(hex: "8166FF")
    static let darkSurfaceBg     = Color(hex: "343436")
    static let darkTextPrimary   = Color(hex: "FFFFFF")
    static let darkTextSecondary = Color(hex: "A3A3A9")
    static let darkCardBg        = Color(hex: "29292A")
    static let darkAccent        = Color(hex: "A794FF")

    static let coral         = Color(hex: "FF6584")
    static let teal          = Color(hex: "2DBD9B")
    static let amber         = Color(hex: "FFB347")
    static let textPrimary   = Color(UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(Color(hex: "FFFFFF")) : UIColor(Color(hex: "1A1A2E")) })
    static let textSecondary = Color(UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(Color(hex: "A3A3A9")) : UIColor(Color(hex: "6B6B8A")) })
    static let divider       = Color(UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(Color(hex: "3A3A3D")) : UIColor(Color(hex: "E4E2F5")) })

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

