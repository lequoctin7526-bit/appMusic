import Foundation

/// Availability status for a track across regions and licenses.
public enum TrackAvailability: String, Codable, Sendable {
    case available
    case restricted
    case geoBlocked
    case requiresSubscription
    case embedDisabled
    case unavailable
}

/// Universal music track representation across all supported providers.
public struct MusicTrack: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let provider: MusicProvider
    public let title: String
    public let artist: String
    public let album: String?
    public let artworkURL: URL?
    public let duration: TimeInterval
    public let providerTrackID: String
    public let youtubeVideoID: String?
    public let appleMusicID: String?
    public let isExplicit: Bool
    public let availability: TrackAvailability
    public let backgroundPlaybackSupported: Bool
    
    // Additional legal & attribution metadata
    public let channelTitle: String?
    public let publishedAt: Date?
    public let copyrightAttribution: String?
    public let streamURL: URL?
    public let isVietnameseChannel: Bool

    public init(
        id: UUID = UUID(),
        provider: MusicProvider,
        title: String,
        artist: String,
        album: String? = nil,
        artworkURL: URL? = nil,
        duration: TimeInterval = 0,
        providerTrackID: String,
        youtubeVideoID: String? = nil,
        appleMusicID: String? = nil,
        isExplicit: Bool = false,
        availability: TrackAvailability = .available,
        backgroundPlaybackSupported: Bool? = nil,
        channelTitle: String? = nil,
        publishedAt: Date? = nil,
        copyrightAttribution: String? = nil,
        streamURL: URL? = nil,
        isVietnameseChannel: Bool = false
    ) {
        self.id = id
        self.provider = provider
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.duration = duration
        self.providerTrackID = providerTrackID
        self.youtubeVideoID = youtubeVideoID ?? (provider == .youtube ? providerTrackID : nil)
        self.appleMusicID = appleMusicID ?? (provider == .appleMusic ? providerTrackID : nil)
        self.isExplicit = isExplicit
        self.availability = availability
        self.isVietnameseChannel = isVietnameseChannel
        
        // Strict enforcement: YouTube NEVER supports background playback
        if provider == .youtube {
            self.backgroundPlaybackSupported = false
        } else {
            self.backgroundPlaybackSupported = backgroundPlaybackSupported ?? provider.supportsBackgroundAudio
        }
        
        self.channelTitle = channelTitle
        self.publishedAt = publishedAt
        self.copyrightAttribution = copyrightAttribution
        self.streamURL = streamURL
    }

    /// Formatted duration string (e.g., "03:45" or "1:15:30")
    public var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
