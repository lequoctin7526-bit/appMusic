import Foundation

/// Thread-safe local persistence service storing library, favorites, playlists, and history
public final class StorageService: MusicLibraryProvider, PlaylistProvider, @unchecked Sendable {
    private let fileManager = FileManager.default
    private let storageQueue = DispatchQueue(label: "com.wavemix.storageQueue", attributes: .concurrent)

    private var favorites: [MusicTrack] = []
    private var recentlyPlayed: [MusicTrack] = []
    private var playlists: [MusicPlaylist] = []
    private var searchHistory: [String] = []

    private let favoritesURL: URL
    private let recentlyPlayedURL: URL
    private let playlistsURL: URL
    private let searchHistoryURL: URL

    public init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let wavemixDir = appSupport.appendingPathComponent("WaveMix", isDirectory: true)
        
        try? fileManager.createDirectory(at: wavemixDir, withIntermediateDirectories: true)

        self.favoritesURL = wavemixDir.appendingPathComponent("favorites.json")
        self.recentlyPlayedURL = wavemixDir.appendingPathComponent("recently_played.json")
        self.playlistsURL = wavemixDir.appendingPathComponent("playlists.json")
        self.searchHistoryURL = wavemixDir.appendingPathComponent("search_history.json")

        loadAllData()
    }

    // MARK: - Initial Loading

    private func loadAllData() {
        self.favorites = load([MusicTrack].self, from: favoritesURL) ?? []
        self.recentlyPlayed = load([MusicTrack].self, from: recentlyPlayedURL) ?? []
        self.playlists = load([MusicPlaylist].self, from: playlistsURL) ?? seedDefaultPlaylists()
        self.searchHistory = load([String].self, from: searchHistoryURL) ?? ["Top Hits", "Chill Lofi", "Acoustic Pop"]
    }

    private func seedDefaultPlaylists() -> [MusicPlaylist] {
        return [
            MusicPlaylist(
                title: "WaveMix Launch Favorites",
                playlistDescription: "Curated multi-source tracks for your first listening session.",
                tracks: [
                    MusicTrack(
                        provider: .youtube,
                        title: "Levitating",
                        artist: "Dua Lipa",
                        artworkURL: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600"),
                        duration: 203,
                        providerTrackID: "TUVcZfQe-Kw",
                        youtubeVideoID: "TUVcZfQe-Kw",
                        backgroundPlaybackSupported: false,
                        channelTitle: "Dua Lipa VEVO",
                        copyrightAttribution: "YouTube • Dua Lipa"
                    ),
                    MusicTrack(
                        provider: .licensedCatalog,
                        title: "Midnight City (Acoustic)",
                        artist: "Echoes of Sound",
                        artworkURL: URL(string: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600"),
                        duration: 245,
                        providerTrackID: "lic_001",
                        backgroundPlaybackSupported: true,
                        copyrightAttribution: "Licensed to WaveMix",
                        streamURL: URL(string: "https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Sevish_-__nbsp_.mp3")
                    )
                ],
                isUserCreated: false
            )
        ]
    }

    private func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ object: T, to url: URL) {
        if let data = try? JSONEncoder().encode(object) {
            try? data.write(to: url, options: .atomic)
        }
    }

    // MARK: - Favorites (MusicLibraryProvider)

    public func getFavorites() async throws -> [MusicTrack] {
        storageQueue.sync { favorites }
    }

    public func addFavorite(track: MusicTrack) async throws {
        storageQueue.async(flags: .barrier) {
            if !self.favorites.contains(where: { $0.id == track.id }) {
                self.favorites.insert(track, at: 0)
                self.save(self.favorites, to: self.favoritesURL)
            }
        }
    }

    public func removeFavorite(trackId: UUID) async throws {
        storageQueue.async(flags: .barrier) {
            self.favorites.removeAll(where: { $0.id == trackId })
            self.save(self.favorites, to: self.favoritesURL)
        }
    }

    public func isFavorite(trackId: UUID) async throws -> Bool {
        storageQueue.sync {
            favorites.contains(where: { $0.id == trackId })
        }
    }

    // MARK: - Recently Played

    public func getRecentlyPlayed(limit: Int = 30) async throws -> [MusicTrack] {
        storageQueue.sync {
            Array(recentlyPlayed.prefix(limit))
        }
    }

    public func recordPlayback(track: MusicTrack) async throws {
        storageQueue.async(flags: .barrier) {
            self.recentlyPlayed.removeAll(where: { $0.id == track.id || $0.providerTrackID == track.providerTrackID })
            self.recentlyPlayed.insert(track, at: 0)
            if self.recentlyPlayed.count > 50 {
                self.recentlyPlayed = Array(self.recentlyPlayed.prefix(50))
            }
            self.save(self.recentlyPlayed, to: self.recentlyPlayedURL)
        }
    }

    // MARK: - Playlists (PlaylistProvider)

    public func getAllPlaylists() async throws -> [MusicPlaylist] {
        storageQueue.sync { playlists }
    }

    public func getPlaylist(id: UUID) async throws -> MusicPlaylist? {
        storageQueue.sync {
            playlists.first(where: { $0.id == id })
        }
    }

    public func createPlaylist(title: String, description: String?) async throws -> MusicPlaylist {
        let playlist = MusicPlaylist(
            title: title,
            playlistDescription: description,
            tracks: [],
            isUserCreated: true
        )
        storageQueue.async(flags: .barrier) {
            self.playlists.insert(playlist, at: 0)
            self.save(self.playlists, to: self.playlistsURL)
        }
        return playlist
    }

    public func deletePlaylist(id: UUID) async throws {
        storageQueue.async(flags: .barrier) {
            self.playlists.removeAll(where: { $0.id == id })
            self.save(self.playlists, to: self.playlistsURL)
        }
    }

    public func addTrack(_ track: MusicTrack, to playlistId: UUID) async throws {
        storageQueue.async(flags: .barrier) {
            guard let index = self.playlists.firstIndex(where: { $0.id == playlistId }) else { return }
            var playlist = self.playlists[index]
            if !playlist.tracks.contains(where: { $0.providerTrackID == track.providerTrackID }) {
                playlist.tracks.append(track)
                playlist.updatedAt = Date()
                self.playlists[index] = playlist
                self.save(self.playlists, to: self.playlistsURL)
            }
        }
    }

    public func removeTrack(trackId: UUID, from playlistId: UUID) async throws {
        storageQueue.async(flags: .barrier) {
            guard let index = self.playlists.firstIndex(where: { $0.id == playlistId }) else { return }
            var playlist = self.playlists[index]
            playlist.tracks.removeAll(where: { $0.id == trackId })
            playlist.updatedAt = Date()
            self.playlists[index] = playlist
            self.save(self.playlists, to: self.playlistsURL)
        }
    }

    // MARK: - Search History

    public func getSearchHistory() -> [String] {
        storageQueue.sync { searchHistory }
    }

    public func addSearchHistory(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        storageQueue.async(flags: .barrier) {
            self.searchHistory.removeAll(where: { $0.lowercased() == trimmed.lowercased() })
            self.searchHistory.insert(trimmed, at: 0)
            if self.searchHistory.count > 20 {
                self.searchHistory = Array(self.searchHistory.prefix(20))
            }
            self.save(self.searchHistory, to: self.searchHistoryURL)
        }
    }

    public func clearSearchHistory() {
        storageQueue.async(flags: .barrier) {
            self.searchHistory.removeAll()
            self.save(self.searchHistory, to: self.searchHistoryURL)
        }
    }
}
