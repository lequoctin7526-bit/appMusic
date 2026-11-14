import SwiftUI

/// Persistent mini player anchored above the bottom tab navigation
public struct MiniPlayerView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    public init() {}

    public var body: some View {
        if let track = playbackService.currentTrack {
            Button(action: { playbackService.isMiniPlayerExpanded = true }) {
                VStack(spacing: 0) {
                    // Progress indicator line at top of miniplayer
                    GeometryReader { geo in
                        let progress = playbackService.duration > 0 ? playbackService.currentTime / playbackService.duration : 0
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 2)
                            Rectangle()
                                .fill(WaveMixColors.brandGradient)
                                .frame(width: geo.size.width * CGFloat(progress), height: 2)
                        }
                    }
                    .frame(height: 2)

                    HStack(spacing: 12) {
                        // Artwork
                        AsyncArtworkView(url: track.artworkURL, provider: track.provider, cornerRadius: 6)
                            .frame(width: 44, height: 44)

                        // Title & Artist
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(WaveMixColors.textPrimary)
                                .lineLimit(1)

                            HStack(spacing: 6) {
                                Text(track.artist)
                                    .font(.system(size: 12))
                                    .foregroundColor(WaveMixColors.textSecondary)
                                    .lineLimit(1)

                                ProviderBadgeView(provider: track.provider, showCapability: false)
                            }
                        }

                        Spacer()

                        // Controls
                        HStack(spacing: 16) {
                            Button(action: { playbackService.togglePlayPause() }) {
                                Image(systemName: playbackService.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(WaveMixColors.textPrimary)
                            }
                            .buttonStyle(.plain)

                            Button(action: { playbackService.next() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(WaveMixColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.trailing, 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(WaveMixColors.surfaceDark)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(WaveMixColors.surfaceBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 10, y: 4)
                .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
        }
    }
}
