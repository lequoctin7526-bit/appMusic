import SwiftUI
import AVKit

/// Full-screen modal player offering distinct experiences for YouTube (visual embedded)
/// and Native Licensed Music (album art, waveforms, background audio controls).
public struct FullPlayerView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService
    @Environment(\.dismiss) private var dismiss

    @State private var isDraggingScrubber: Bool = false
    @State private var scrubbedTime: Double = 0

    public init() {}

    public var body: some View {
        ZStack {
            WaveMixColors.playerGradient.ignoresSafeArea()

            if let track = playbackService.currentTrack {
                VStack(spacing: 0) {
                    // Top Bar (Grabber & Dismiss)
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(WaveMixColors.textSecondary)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("PLAYING FROM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(WaveMixColors.textTertiary)
                            Text(track.provider.displayName.uppercased())
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(track.provider.brandColor)
                        }

                        Spacer()

                        Button(action: { playbackService.showLicensedMatchSheet = true }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(WaveMixColors.textSecondary)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Content Area: YouTube Player vs Native Audio Player
                    if track.provider == .youtube {
                        youtubePlayerSection(track: track)
                    } else {
                        nativeAudioPlayerSection(track: track)
                    }

                    Spacer(minLength: 16)
                }
                .padding(.bottom, 24)
            } else {
                Text("No track currently playing")
                    .foregroundColor(WaveMixColors.textSecondary)
            }
        }
        .sheet(isPresented: $playbackService.showLicensedMatchSheet) {
            if let track = playbackService.currentTrack {
                SmartSourceSwitchSheet(sourceTrack: track) { chosenTrack in
                    playbackService.switchToTrack(track: chosenTrack)
                }
            }
        }
    }

    // MARK: - YouTube Player Interface

    private func youtubePlayerSection(track: MusicTrack) -> some View {
        VStack(spacing: 16) {
            // Official Embedded IFrame Player (Min 200x200 CSS px enforced)
            ZStack {
                Color.black
                if let videoID = track.youtubeVideoID {
                    YouTubePlayerWebView(videoID: videoID, controller: playbackService.youtubeController)
                }
            }
            .frame(height: 230)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .shadow(color: Color.black.opacity(0.5), radius: 12, y: 6)

            // Video Title & Channel Info
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(WaveMixColors.textPrimary)
                            .lineLimit(2)

                        Text(track.channelTitle ?? track.artist)
                            .font(.system(size: 14))
                            .foregroundColor(WaveMixColors.textSecondary)
                    }

                    Spacer()

                    ProviderBadgeView(provider: .youtube)
                }

                // Official YouTube Link
                if let videoID = track.youtubeVideoID, let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                    Link(destination: url) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open in YouTube")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.red)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 20)

            // Policy Notice Banner
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color.orange)
                Text("YouTube playback requires the screen to remain on. Locking the screen will pause playback.")
                    .font(.system(size: 11))
                    .foregroundColor(WaveMixColors.textSecondary)
            }
            .padding(10)
            .background(WaveMixColors.surfaceDark)
            .cornerRadius(10)
            .padding(.horizontal, 20)

            Spacer()

            // Smart Switch Call-to-action
            Button(action: { playbackService.showLicensedMatchSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "headphones")
                        .font(.system(size: 16, weight: .bold))
                    Text("FIND LICENSED VERSION FOR BACKGROUND PLAY")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(WaveMixColors.brandGradient)
                .cornerRadius(12)
                .shadow(color: WaveMixColors.accentViolet.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Native Music Player Interface

    private func nativeAudioPlayerSection(track: MusicTrack) -> some View {
        VStack(spacing: 20) {
            Spacer()

            // Large Album Artwork
            ZStack {
                AsyncArtworkView(url: track.artworkURL, provider: track.provider, cornerRadius: 20)
                    .frame(width: 280, height: 280)
                    .shadow(color: WaveMixColors.accentViolet.opacity(0.35), radius: 24, y: 12)

                // Subtle visualizer overlay when playing
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        WaveformVisualizerView(isPlaying: playbackService.isPlaying, barCount: 5)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding(12)
                    }
                }
                .frame(width: 280, height: 280)
            }

            // Track & Artist Title
            VStack(spacing: 4) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(WaveMixColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .padding(.horizontal, 24)

                Text(track.artist)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .lineLimit(1)

                if let album = track.album {
                    Text(album)
                        .font(.system(size: 13))
                        .foregroundColor(WaveMixColors.textTertiary)
                        .lineLimit(1)
                }

                ProviderBadgeView(provider: track.provider)
                    .padding(.top, 4)
            }

            // Scrubber Slider
            VStack(spacing: 6) {
                let duration = max(1.0, playbackService.duration)
                let current = isDraggingScrubber ? scrubbedTime : playbackService.currentTime

                Slider(value: Binding(
                    get: { current },
                    set: { newValue in
                        isDraggingScrubber = true
                        scrubbedTime = newValue
                    }
                ), in: 0...duration) { editing in
                    if !editing {
                        playbackService.seek(to: scrubbedTime)
                        isDraggingScrubber = false
                    }
                }
                .tint(WaveMixColors.accentCyan)

                HStack {
                    Text(formatTime(current))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WaveMixColors.textTertiary)
                    Spacer()
                    Text("-\(formatTime(max(0, duration - current)))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(WaveMixColors.textTertiary)
                }
            }
            .padding(.horizontal, 28)

            // Playback Controls
            HStack(spacing: 24) {
                Button(action: { playbackService.toggleShuffle() }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                        .foregroundColor(playbackService.queue.isShuffled ? WaveMixColors.accentCyan : WaveMixColors.textTertiary)
                }

                Button(action: { playbackService.previous() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(WaveMixColors.textPrimary)
                }

                Button(action: { playbackService.togglePlayPause() }) {
                    ZStack {
                        Circle()
                            .fill(WaveMixColors.brandGradient)
                            .frame(width: 68, height: 68)
                            .shadow(color: WaveMixColors.accentViolet.opacity(0.4), radius: 10, y: 4)

                        Image(systemName: playbackService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Button(action: { playbackService.next() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .foregroundColor(WaveMixColors.textPrimary)
                }

                Button(action: { playbackService.cycleRepeatMode() }) {
                    Image(systemName: playbackService.queue.repeatMode.systemIcon)
                        .font(.system(size: 18))
                        .foregroundColor(playbackService.queue.repeatMode != .off ? WaveMixColors.accentCyan : WaveMixColors.textTertiary)
                }
            }
            .padding(.horizontal, 20)

            // Status Tag
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(Color.green)
                    .font(.system(size: 11))
                Text("Lock Screen & Background Audio Active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.green)
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds > 0 && !seconds.isNaN else { return "00:00" }
        let total = Int(seconds)
        let min = total / 60
        let sec = total % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
