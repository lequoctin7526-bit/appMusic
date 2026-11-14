import SwiftUI

/// Cinematic Splash Screen & Intro Animation
/// Duration: ~1.5s, respects iOS Reduce Motion
public struct SplashScreenView: View {
    public let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stage1LogoFadeIn: Bool = false
    @State private var stage2EqualizerPulsing: Bool = false
    @State private var stage3TextReveal: Bool = false
    @State private var waveRings: [CGFloat] = [0.6, 0.9, 1.2]

    public init(onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            WaveMixColors.midnightBlack.ignoresSafeArea()

            // Ambient background glow expanding
            RadialGradient(
                colors: [
                    WaveMixColors.deepPurple.opacity(stage1LogoFadeIn ? 0.35 : 0.0),
                    WaveMixColors.electricBlue.opacity(stage2EqualizerPulsing ? 0.20 : 0.0),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()

            // Soundwave ripple rings
            if stage2EqualizerPulsing && !reduceMotion {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [WaveMixColors.electricBlue.opacity(0.4), WaveMixColors.neonCyan.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 180 * waveRings[i], height: 180 * waveRings[i])
                        .opacity(Double(1.5 - waveRings[i] / 1.5))
                        .animation(
                            Animation.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.3),
                            value: waveRings[i]
                        )
                }
            }

            VStack(spacing: 24) {
                // Central Stylized 'W' Logo
                WaveMixLogoView(
                    size: 110,
                    isPulsing: stage2EqualizerPulsing,
                    showWordmark: false
                )
                .scaleEffect(stage1LogoFadeIn ? 1.0 : 0.75)
                .opacity(stage1LogoFadeIn ? 1.0 : 0.0)

                // Stage 3: Wordmark & Tagline
                VStack(spacing: 8) {
                    Text("WAVEMIX")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(WaveMixColors.neonAccentGradient)
                        .tracking(4)

                    Text(WaveMixColors.brandTagline)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(WaveMixColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(stage3TextReveal ? 1.0 : 0.0)
                .offset(y: stage3TextReveal ? 0 : 10)
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        if reduceMotion {
            // Immediate fade in and quick finish
            withAnimation(.easeIn(duration: 0.4)) {
                stage1LogoFadeIn = true
                stage3TextReveal = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onFinished()
            }
            return
        }

        // Stage 1: Logo Fade In (0.0s - 0.4s)
        withAnimation(.easeOut(duration: 0.5)) {
            stage1LogoFadeIn = true
        }

        // Stage 2: Equalizer Pulse & Glow (0.4s - 0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.6)) {
                stage2EqualizerPulsing = true
                waveRings = [1.2, 1.6, 2.0]
            }
        }

        // Stage 3: Wordmark & Tagline Reveal (0.8s - 1.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                stage3TextReveal = true
            }
        }

        // Smooth transition to app (1.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.35)) {
                onFinished()
            }
        }
    }
}
