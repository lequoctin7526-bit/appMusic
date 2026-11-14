import SwiftUI

/// Badging view displaying content provider with attribution and background capability
public struct ProviderBadgeView: View {
    public let provider: MusicProvider
    public var showCapability: Bool = true

    public init(provider: MusicProvider, showCapability: Bool = true) {
        self.provider = provider
        self.showCapability = showCapability
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: provider.systemIcon)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(provider.brandColor)

            Text(provider.displayName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)

            if showCapability {
                if provider.supportsBackgroundAudio {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color.green)
                        .help("Background Audio Supported")
                } else {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color.orange)
                        .help("Foreground Screen Only")
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(WaveMixColors.surfaceElevated)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(provider.brandColor.opacity(0.3), lineWidth: 0.8)
        )
    }
}
