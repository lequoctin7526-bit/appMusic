import Foundation

/// Represents a unified user playlist which can contain tracks from different providers.
public struct MusicPlaylist: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var playlistDescription: String?
    public var coverImageURL: URL?
    public var tracks: [MusicTrack]
    public let createdAt: Date
    public var updatedAt: Date
    public let isUserCreated: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        playlistDescription: String? = nil,
        coverImageURL: URL? = nil,
        tracks: [MusicTrack] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isUserCreated: Bool = true
    ) {
        self.id = id
        self.title = title
        self.playlistDescription = playlistDescription
        self.coverImageURL = coverImageURL
        self.tracks = tracks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isUserCreated = isUserCreated
    }

    /// Summary of providers included in this playlist
    public var containedProviders: [MusicProvider] {
        Array(Set(tracks.map { $0.provider })).sorted(by: { $0.rawValue < $1.rawValue })
    }

    /// Count of tracks that support background playback
    public var backgroundPlayableTrackCount: Int {
        tracks.filter { $0.backgroundPlaybackSupported }.count
    }

    /// True if all tracks support background playback
    public var isFullyBackgroundCapable: Bool {
        tracks.allSatisfy { $0.backgroundPlaybackSupported }
    }
}
