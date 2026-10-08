import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Design Tokens - Pastel Rose & Lavender
    static let cycleRose = Color(hex: "#FF5376")
    static let cycleRoseLight = Color(hex: "#FFD9E2")
    static let cycleLavender = Color(hex: "#8B5CF6")
    static let cycleLavenderLight = Color(hex: "#EDE9FE")
    static let cyclePeach = Color(hex: "#FF8E72")

    // Cycle Status Highlights
    static let periodRed = Color(hex: "#FF486A")
    static let periodPink = Color(hex: "#FFC0CD")
    static let fertilePurple = Color(hex: "#9D65E8")
    static let fertileLight = Color(hex: "#EADBFF")
    static let ovulationTeal = Color(hex: "#38BDF8")

    // Background & Surfaces
    static let cycleBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#131012")) : UIColor(Color(hex: "#FFF9FA"))
    })
    static let cycleSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#1F1B1E")) : UIColor.white
    })
    static let cycleSurfaceVariant = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color(hex: "#2C272B")) : UIColor(Color(hex: "#F6F0F2"))
    })
}
