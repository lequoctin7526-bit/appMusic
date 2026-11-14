import SwiftUI

/// WaveMix Premium Brand Identity & Design System Color Palette
/// Tagline: "Feel Every Beat. Discover Every Song."
public enum WaveMixColors {
    // Official Brand Palette
    public static let midnightBlack = Color(red: 11/255, green: 11/255, blue: 18/255)   // #0B0B12
    public static let deepPurple = Color(red: 108/255, green: 66/255, blue: 217/255)     // #6C42D9
    public static let electricBlue = Color(red: 49/255, green: 139/255, blue: 255/255)   // #318BFF
    public static let neonCyan = Color(red: 66/255, green: 232/255, blue: 216/255)       // #42E8D8
    public static let accentPink = Color(red: 214/255, green: 109/255, blue: 255/255)    // #D66DFF

    // App Surfaces (Dark Luxury Theme)
    public static let backgroundDark = midnightBlack
    public static let surfaceDark = Color(red: 18/255, green: 18/255, blue: 28/255)      // #12121C
    public static let surfaceElevated = Color(red: 26/255, green: 26/255, blue: 40/255)  // #1A1A28
    public static let surfaceBorder = Color(white: 1.0, opacity: 0.08)

    // Aliases for component compatibility
    public static let accentViolet = deepPurple
    public static let accentCyan = neonCyan

    // Signature Gradients
    public static let brandGradient = LinearGradient(
        colors: [deepPurple, electricBlue, neonCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let neonAccentGradient = LinearGradient(
        colors: [electricBlue, neonCyan, accentPink],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let playerGradient = LinearGradient(
        colors: [Color(red: 30/255, green: 18/255, blue: 60/255), midnightBlack],
        startPoint: .top,
        endPoint: .bottom
    )

    public static let splashGlowGradient = RadialGradient(
        gradient: Gradient(colors: [deepPurple.opacity(0.6), electricBlue.opacity(0.3), Color.clear]),
        center: .center,
        startRadius: 20,
        endRadius: 220
    )

    // Text & Controls
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.70)
    public static let textTertiary = Color(white: 0.45)
    public static let divider = Color(white: 1.0, opacity: 0.06)

    // Brand Tagline
    public static let brandTagline = "Feel Every Beat. Discover Every Song."
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
