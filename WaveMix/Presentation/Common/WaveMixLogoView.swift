import SwiftUI

/// Native SwiftUI component rendering the official WaveMix soundwave 'W' logo
public struct WaveMixLogoView: View {
    public var size: CGFloat = 80
    public var isPulsing: Bool = false
    public var showWordmark: Bool = false

    @State private var wavePhase: CGFloat = 0

    public init(size: CGFloat = 80, isPulsing: Bool = false, showWordmark: Bool = false) {
        self.size = size
        self.isPulsing = isPulsing
        self.showWordmark = showWordmark
    }

    // Relative height configuration for the 7 equalizer bars forming 'W'
    private let barRatios: [(baseH: CGFloat, phaseOffset: Double)] = [
        (0.72, 0.0),   // Left outer high
        (0.92, 0.2),   // Left inner high
        (0.55, 0.4),   // Left valley
        (0.85, 0.6),   // Center peak
        (0.55, 0.8),   // Right valley
        (0.92, 1.0),   // Right inner high
        (0.72, 1.2)    // Right outer high
    ]

    public var body: some View {
        VStack(spacing: size * 0.15) {
            ZStack {
                // Background radial glow
                if isPulsing {
                    Circle()
                        .fill(WaveMixColors.splashGlowGradient)
                        .frame(width: size * 1.8, height: size * 1.8)
                        .scaleEffect(isPulsing ? 1.05 : 0.95)
                        .opacity(isPulsing ? 0.9 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }

                // 7 Soundwave Bars forming 'W'
                HStack(spacing: size * 0.04) {
                    ForEach(0..<barRatios.count, id: \.self) { idx in
                        let config = barRatios[idx]
                        let animatedRatio = isPulsing ?
                            config.baseH + CGFloat(sin(wavePhase + config.phaseOffset) * 0.12) :
                            config.baseH

                        RoundedRectangle(cornerRadius: size * 0.035)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        WaveMixColors.deepPurple,
                                        WaveMixColors.electricBlue,
                                        WaveMixColors.neonCyan
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: size * 0.09,
                                height: size * max(0.2, min(1.0, animatedRatio))
                            )
                            .shadow(color: WaveMixColors.electricBlue.opacity(0.4), radius: size * 0.06, y: 0)
                    }
                }
                .frame(width: size, height: size)
            }

            if showWordmark {
                VStack(spacing: 4) {
                    Text("WAVEMIX")
                        .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                        .foregroundStyle(WaveMixColors.neonAccentGradient)
                        .tracking(3)

                    Text(WaveMixColors.brandTagline)
                        .font(.system(size: size * 0.11, weight: .medium))
                        .foregroundColor(WaveMixColors.textSecondary)
                }
            }
        }
        .onAppear {
            if isPulsing {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    wavePhase = .pi * 2
                }
            }
        }
    }
}
