import Foundation
import MediaPlayer
import UIKit

/// Manages Lock Screen and Control Center Now Playing information.
/// STRICT COMPLIANCE:
/// Only licensed background-capable sources publish active playback info.
/// YouTube playback clears or locks NowPlayingInfo to avoid violating YouTube terms.
public final class NowPlayingService: @unchecked Sendable {
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()

    public init() {}

    /// Updates Now Playing metadata for licensed tracks
    public func updateNowPlaying(
        track: MusicTrack,
        currentTime: TimeInterval,
        isPlaying: Bool,
        artworkImage: UIImage? = nil
    ) {
        guard track.backgroundPlaybackSupported else {
            // Never expose YouTube to background NowPlayingCenter
            clear()
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: track.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPMediaItemPropertyMediaType: MPMediaType.music.rawValue
        ]

        if let album = track.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }

        if let image = artworkImage {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = artwork
        }

        nowPlayingCenter.nowPlayingInfo = info
    }

    /// Clears lock screen information
    public func clear() {
        nowPlayingCenter.nowPlayingInfo = nil
    }
}
