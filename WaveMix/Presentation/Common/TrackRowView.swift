import SwiftUI

/// Unified track list row displaying artwork, title, artist, provider badge, and action context menu
public struct TrackRowView: View {
    public let track: MusicTrack
    public let isCurrentlyPlaying: Bool
    public let onSelect: () -> Void
    public var onFindLicensed: (() -> Void)? = nil
    public var onAddToPlaylist: (() -> Void)? = nil
    public var onToggleFavorite: (() -> Void)? = nil

    public init(
        track: MusicTrack,
        isCurrentlyPlaying: Bool = false,
        onSelect: @escaping () -> Void,
        onFindLicensed: (() -> Void)? = nil,
        onAddToPlaylist: (() -> Void)? = nil,
        onToggleFavorite: (() -> Void)? = nil
    ) {
        self.track = track
        self.isCurrentlyPlaying = isCurrentlyPlaying
        self.onSelect = onSelect
        self.onFindLicensed = onFindLicensed
        self.onAddToPlaylist = onAddToPlaylist
        self.onToggleFavorite = onToggleFavorite
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Artwork
                ZStack(alignment: .bottomTrailing) {
                    AsyncArtworkView(url: track.artworkURL, provider: track.provider, cornerRadius: 8)
                        .frame(width: 52, height: 52)

                    if isCurrentlyPlaying {
                        ZStack {
                            Color.black.opacity(0.6)
                            WaveformVisualizerView(isPlaying: true, barCount: 3)
                        }
                        .frame(width: 52, height: 52)
                        .cornerRadius(8)
                    }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isCurrentlyPlaying ? WaveMixColors.accentCyan : WaveMixColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(track.artist)
                            .font(.system(size: 13))
                            .foregroundColor(WaveMixColors.textSecondary)
                            .lineLimit(1)

                        if track.isExplicit {
                            Text("E")
                                .font(.system(size: 9, weight: .heavy))
                                .padding(.horizontal, 3)
                                .background(WaveMixColors.surfaceElevated)
                                .foregroundColor(WaveMixColors.textSecondary)
                                .cornerRadius(2)
                        }
                    }

                    ProviderBadgeView(provider: track.provider)
                }

                Spacer()

                // Duration & Options
                VStack(alignment: .trailing, spacing: 4) {
                    Text(track.formattedDuration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WaveMixColors.textTertiary)

                    if track.provider == .youtube {
                        Button(action: { onFindLicensed?() }) {
                            Image(systemName: "headphones")
                                .font(.system(size: 13))
                                .foregroundColor(WaveMixColors.accentViolet)
                        }
                        .buttonStyle(.borderless)
                        .help("Find Licensed Version for Background Audio")
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isCurrentlyPlaying ? WaveMixColors.surfaceDark.opacity(0.8) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onSelect) {
                Label("Play Now", systemImage: "play.fill")
            }

            if track.provider == .youtube, let onFindLicensed = onFindLicensed {
                Button(action: onFindLicensed) {
                    Label("Find Licensed Version", systemImage: "headphones")
                }
            }

            if let onAddToPlaylist = onAddToPlaylist {
                Button(action: onAddToPlaylist) {
                    Label("Add to Playlist", systemImage: "text.badge.plus")
                }
            }

            if let onToggleFavorite = onToggleFavorite {
                Button(action: onToggleFavorite) {
                    Label("Favorite", systemImage: "heart")
                }
            }
        }
    }
}
