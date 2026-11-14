import SwiftUI

/// WaveMix Premium Design System Color Palette
public enum WaveMixColors {
    // Backgrounds
    public static let backgroundDark = Color(red: 0.04, green: 0.05, blue: 0.07) // Deep Obsidian #0A0D12
    public static let surfaceDark = Color(red: 0.09, green: 0.11, blue: 0.16)    // Dark Slate #171C28
    public static let surfaceElevated = Color(red: 0.13, green: 0.16, blue: 0.22) // Elevated Card #212938
    public static let surfaceBorder = Color(white: 1.0, opacity: 0.08)

    // Accents & Gradients
    public static let accentViolet = Color(red: 0.54, green: 0.17, blue: 0.89)  // Electric Violet #8A2BE2
    public static let accentCyan = Color(red: 0.0, green: 0.82, blue: 1.0)       // Neon Cyan #00D2FF
    public static let accentPink = Color(red: 0.98, green: 0.20, blue: 0.52)     // Vibrant Pink #FA3384

    public static let brandGradient = LinearGradient(
        colors: [accentViolet, accentCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let playerGradient = LinearGradient(
        colors: [Color(red: 0.12, green: 0.08, blue: 0.24), backgroundDark],
        startPoint: .top,
        endPoint: .bottom
    )

    // Text & Controls
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textTertiary = Color(white: 0.40)
    public static let divider = Color(white: 1.0, opacity: 0.06)
}

extension View {
    public func waveMixCardStyle() -> some View {
        self
            .background(WaveMixColors.surfaceDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(WaveMixColors.surfaceBorder, lineWidth: 1)
            )
    }
}
