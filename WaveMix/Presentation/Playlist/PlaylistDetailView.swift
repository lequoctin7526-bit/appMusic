import SwiftUI

/// Playlist detail view displaying multi-provider tracks and background compatibility breakdown
public struct PlaylistDetailView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State public var playlist: MusicPlaylist
    private let storageService = StorageService()

    public init(playlist: MusicPlaylist) {
        _playlist = State(initialValue: playlist)
    }

    public var body: some View {
        ZStack {
            WaveMixColors.backgroundDark.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Artwork & Info
                    headerSection

                    // Action Controls
                    actionButtonsSection

                    // Multi-source capability warning / notice
                    complianceNoticeSection

                    // Tracks List
                    tracksSection
                }
                .padding(.bottom, 90)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(WaveMixColors.surfaceElevated)
                    .frame(width: 100, height: 100)

                Image(systemName: "music.note.list")
                    .font(.system(size: 40))
                    .foregroundColor(WaveMixColors.accentViolet)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(WaveMixColors.textPrimary)

                if let desc = playlist.playlistDescription {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(WaveMixColors.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text("\(playlist.tracks.count) tracks")
                        .font(.system(size: 12))
                        .foregroundColor(WaveMixColors.textTertiary)

                    ForEach(playlist.containedProviders) { p in
                        ProviderBadgeView(provider: p, showCapability: false)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                if let first = playlist.tracks.first {
                    playbackService.play(track: first, in: playlist.tracks)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Play All")
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(WaveMixColors.brandGradient)
                .cornerRadius(12)
            }
            .disabled(playlist.tracks.isEmpty)
        }
        .padding(.horizontal, 16)
    }

    private var complianceNoticeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !playlist.isFullyBackgroundCapable {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.orange)
                        .font(.system(size: 13))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mixed-Provider Playlist")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(WaveMixColors.textPrimary)

                        Text("This playlist contains YouTube videos (\(playlist.tracks.count - playlist.backgroundPlayableTrackCount) items) which cannot play in the background. The queue will pause when reaching a YouTube video if your screen is locked.")
                            .font(.system(size: 11))
                            .foregroundColor(WaveMixColors.textSecondary)
                    }
                }
                .padding(12)
                .background(WaveMixColors.surfaceDark)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracks")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 4) {
                ForEach(playlist.tracks) { track in
                    TrackRowView(
                        track: track,
                        isCurrentlyPlaying: playbackService.currentTrack?.id == track.id,
                        onSelect: {
                            playbackService.play(track: track, in: playlist.tracks)
                        },
                        onFindLicensed: {
                            playbackService.showLicensedMatchSheet = true
                        }
                    )
                }
            }
        }
    }
}
