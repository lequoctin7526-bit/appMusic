import SwiftUI

/// 4-Step Onboarding sequence introducing WaveMix capabilities and creator attribution
public struct OnboardingView: View {
    public let onComplete: () -> Void

    @State private var currentStep: Int = 0

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            WaveMixColors.midnightBlack.ignoresSafeArea()

            // Subtle ambient background gradient
            RadialGradient(
                colors: [
                    WaveMixColors.deepPurple.opacity(0.25),
                    WaveMixColors.midnightBlack
                ],
                center: .top,
                startRadius: 40,
                endRadius: 450
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar: Back & Skip
                topBarView

                // Main Paged Content
                TabView(selection: $currentStep) {
                    step1WelcomeView.tag(0)
                    step2DiscoverView.tag(1)
                    step3MultiSourceView.tag(2)
                    step4VietnamView.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentStep)

                // Bottom Bar: Progress Indicator & Action Buttons
                bottomBarView
            }
        }
    }

    // MARK: - Top Bar

    private var topBarView: some View {
        HStack {
            if currentStep > 0 {
                Button(action: {
                    withAnimation { currentStep -= 1 }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                        Text("Quay lại")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(WaveMixColors.textSecondary)
                }
            } else {
                Spacer().frame(width: 60)
            }

            Spacer()

            if currentStep < 3 {
                Button("Bỏ qua") {
                    onComplete()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(WaveMixColors.textTertiary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(height: 44)
    }

    // MARK: - Onboarding Steps

    private var step1WelcomeView: some View {
        VStack(spacing: 28) {
            Spacer()

            WaveMixLogoView(size: 120, isPulsing: true, showWordmark: false)
                .shadow(color: WaveMixColors.deepPurple.opacity(0.6), radius: 30, y: 0)

            VStack(spacing: 12) {
                Text("App được tạo bởi Quốc Tín")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Khám phá âm nhạc từ nhiều nguồn trong cùng một ứng dụng.")
                    .font(.system(size: 15))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private var step2DiscoverView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(WaveMixColors.surfaceElevated)
                    .frame(width: 140, height: 140)

                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(WaveMixColors.brandGradient)
            }

            VStack(spacing: 12) {
                Text("Discover Your Favorite Music")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Tìm kiếm nhạc, video âm nhạc và khám phá các xu hướng mới.")
                    .font(.system(size: 15))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private var step3MultiSourceView: some View {
        VStack(spacing: 28) {
            Spacer()

            // Visual provider icons cluster
            HStack(spacing: 16) {
                providerIconCard(icon: "play.rectangle.fill", name: "YouTube", color: Color.red)
                providerIconCard(icon: "music.note", name: "Apple Music", color: WaveMixColors.accentPink)
                providerIconCard(icon: "shield.checkerboard", name: "Licensed", color: WaveMixColors.neonCyan)
            }

            VStack(spacing: 12) {
                Text("One Library. Multiple Sources.")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Quản lý nội dung từ nhiều nhà cung cấp và trải nghiệm phát nhạc theo quyền hỗ trợ của từng nguồn.")
                    .font(.system(size: 15))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    private var step4VietnamView: some View {
        VStack(spacing: 28) {
            Spacer()

            // Vietnam music badges
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(WaveMixColors.surfaceElevated)
                        .frame(width: 130, height: 130)

                    Image(systemName: "star.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(WaveMixColors.neonAccentGradient)
                }

                HStack(spacing: 8) {
                    genreBadge("V-Pop")
                    genreBadge("Rap Việt")
                    genreBadge("Indie")
                    genreBadge("Bolero")
                }
            }

            VStack(spacing: 12) {
                Text("Discover Vietnamese Music")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Khám phá V-Pop, Rap Việt, Indie, Bolero và những xu hướng âm nhạc thịnh hành tại Việt Nam.")
                    .font(.system(size: 15))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    // MARK: - Bottom Controls

    private var bottomBarView: some View {
        VStack(spacing: 20) {
            // 4-Step Dots
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentStep ? WaveMixColors.neonCyan : Color.white.opacity(0.2))
                        .frame(width: idx == currentStep ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: currentStep)
                }
            }

            // Action Button
            Button(action: {
                if currentStep < 3 {
                    withAnimation { currentStep += 1 }
                } else {
                    onComplete()
                }
            }) {
                Text(currentStep == 3 ? "Bắt Đầu Ngay" : "Tiếp tục")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(WaveMixColors.brandGradient)
                    .cornerRadius(14)
                    .shadow(color: WaveMixColors.electricBlue.opacity(0.4), radius: 10, y: 4)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 36)
    }

    // MARK: - Helpers

    private func providerIconCard(icon: String, name: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(WaveMixColors.surfaceElevated)
                    .frame(width: 68, height: 68)

                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
            }

            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(WaveMixColors.textSecondary)
        }
    }

    private func genreBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(WaveMixColors.surfaceElevated)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(WaveMixColors.neonCyan.opacity(0.4), lineWidth: 1)
            )
    }
}
