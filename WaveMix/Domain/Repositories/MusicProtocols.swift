import Foundation

/// Filter options for music searches
public enum SearchCategory: String, Codable, CaseIterable, Sendable {
    case all = "all"
    case songs = "songs"
    case artists = "artists"
    case albums = "albums"
    case videos = "videos"
    case playlists = "playlists"
}

public struct SearchFilter: Equatable, Sendable {
    public var provider: MusicProvider? // nil means search all or primary
    public var category: SearchCategory
    public var limit: Int

    public init(provider: MusicProvider? = nil, category: SearchCategory = .all, limit: Int = 25) {
        self.provider = provider
        self.category = category
        self.limit = limit
    }
}

public struct SearchResultPage: Equatable, Sendable {
    public let provider: MusicProvider
    public let tracks: [MusicTrack]
    public let nextPageToken: String?
    public let totalResults: Int?

    public init(
        provider: MusicProvider,
        tracks: [MusicTrack],
        nextPageToken: String? = nil,
        totalResults: Int? = nil
    ) {
        self.provider = provider
        self.tracks = tracks
        self.nextPageToken = nextPageToken
        self.totalResults = totalResults
    }
}

/// Protocol for searching music across different content providers
public protocol MusicSearchProvider: Sendable {
    var provider: MusicProvider { get }
    func search(query: String, filter: SearchFilter, pageToken: String?) async throws -> SearchResultPage
}

/// Protocol for controlling playback of specific music providers
public protocol MusicPlaybackProvider: AnyObject, Sendable {
    var provider: MusicProvider { get }
    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    
    func prepare(track: MusicTrack) async throws
    func play() async throws
    func pause() async throws
    func stop() async throws
    func seek(to seconds: TimeInterval) async throws
}

/// Protocol for user library interactions
public protocol MusicLibraryProvider: Sendable {
    func getFavorites() async throws -> [MusicTrack]
    func addFavorite(track: MusicTrack) async throws
    func removeFavorite(trackId: UUID) async throws
    func isFavorite(trackId: UUID) async throws -> Bool
    
    func getRecentlyPlayed(limit: Int) async throws -> [MusicTrack]
    func recordPlayback(track: MusicTrack) async throws
}

/// Protocol for managing playlists
public protocol PlaylistProvider: Sendable {
    func getAllPlaylists() async throws -> [MusicPlaylist]
    func getPlaylist(id: UUID) async throws -> MusicPlaylist?
    func createPlaylist(title: String, description: String?) async throws -> MusicPlaylist
    func deletePlaylist(id: UUID) async throws
    func addTrack(_ track: MusicTrack, to playlistId: UUID) async throws
    func removeTrack(trackId: UUID, from playlistId: UUID) async throws
}
