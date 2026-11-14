import Foundation
import MediaPlayer

/// Local device library provider accessing music synced via iTunes / Apple Music local library
public final class LocalLibraryService: MusicSearchProvider, @unchecked Sendable {
    public let provider: MusicProvider = .localLibrary

    public init() {}

    public func search(query: String, filter: SearchFilter, pageToken: String?) async throws -> SearchResultPage {
        let queryLower = query.lowercased()
        let mediaQuery = MPMediaQuery.songs()
        
        let items = mediaQuery.items ?? []
        let matched = items.filter { item in
            let title = item.title?.lowercased() ?? ""
            let artist = item.artist?.lowercased() ?? ""
            return title.contains(queryLower) || artist.contains(queryLower)
        }

        let tracks: [MusicTrack] = matched.prefix(filter.limit).map { item in
            let artworkURL: URL? = nil
            if let artwork = item.artwork {
                _ = artwork.image(at: CGSize(width: 300, height: 300))
            }
            return MusicTrack(
                provider: .localLibrary,
                title: item.title ?? "Unknown Title",
                artist: item.artist ?? "Unknown Artist",
                album: item.albumTitle,
                artworkURL: artworkURL,
                duration: item.playbackDuration,
                providerTrackID: "\(item.persistentID)",
                isExplicit: false,
                availability: .available,
                backgroundPlaybackSupported: true,
                copyrightAttribution: "Local Device Storage"
            )
        }

        return SearchResultPage(
            provider: .localLibrary,
            tracks: tracks,
            nextPageToken: nil,
            totalResults: tracks.count
        )
    }
}
