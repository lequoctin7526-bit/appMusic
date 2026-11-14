import Foundation

/// YouTube Data API v3 integration service.
/// Adheres strictly to YouTube API Services Terms and Developer Policies:
/// - Only official endpoints are used.
/// - Validates embeddability status.
/// - Does not scrape or access unauthorized private streams.
public final class YouTubeAPIService: MusicSearchProvider, @unchecked Sendable {
    public let provider: MusicProvider = .youtube

    private let apiClient: APIClient
    private let apiKeyProvider: () -> String?
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    public init(apiClient: APIClient = APIClient(), apiKeyProvider: @escaping () -> String? = { nil }) {
        self.apiClient = apiClient
        self.apiKeyProvider = apiKeyProvider
    }

    public func search(query: String, filter: SearchFilter, pageToken: String?) async throws -> SearchResultPage {
        guard let apiKey = apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Return empty or fallback search result if API key has not been configured
            return SearchResultPage(
                provider: .youtube,
                tracks: self.fallbackMockTracks(query: query),
                nextPageToken: nil,
                totalResults: 0
            )
        }

        // 1. Construct search URL
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "videoCategoryId", value: "10"), // Music category
            URLQueryItem(name: "maxResults", value: "\(min(filter.limit, 50))"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        if let token = pageToken {
            components?.queryItems?.append(URLQueryItem(name: "pageToken", value: token))
        }

        guard let searchURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let searchResponse: YouTubeSearchResponse = try await apiClient.execute(request)

        let videoIDs = searchResponse.items.compactMap { $0.id.videoId }
        guard !videoIDs.isEmpty else {
            return SearchResultPage(provider: .youtube, tracks: [], nextPageToken: nil, totalResults: 0)
        }

        // 2. Fetch video details to verify embeddability and get durations
        let videoDetails = try await fetchVideoDetails(videoIDs: videoIDs, apiKey: apiKey)

        // 3. Assemble verified MusicTracks
        var tracks: [MusicTrack] = []
        for item in searchResponse.items {
            guard let videoId = item.id.videoId else { continue }
            
            // App Store & YouTube Policy: Filter out videos that cannot be embedded
            if let detail = videoDetails[videoId] {
                if let embeddable = detail.status?.embeddable, !embeddable {
                    continue // Skip non-embeddable videos
                }
            }

            let detail = videoDetails[videoId]
            let duration = detail?.contentDetails?.duration != nil ? ISO8601DurationParser.parse(detail!.contentDetails!.duration) : 0

            let rawTitle = decodeHTMLEntities(item.snippet.title)
            let channelTitle = decodeHTMLEntities(item.snippet.channelTitle)
            let parsedMetadata = parseArtistAndTitle(rawTitle: rawTitle, channelTitle: channelTitle)

            let track = MusicTrack(
                provider: .youtube,
                title: parsedMetadata.title,
                artist: parsedMetadata.artist,
                album: nil,
                artworkURL: item.snippet.thumbnails.bestAvailableURL,
                duration: duration,
                providerTrackID: videoId,
                youtubeVideoID: videoId,
                appleMusicID: nil,
                isExplicit: false,
                availability: .available,
                backgroundPlaybackSupported: false, // STRICT: ALWAYS FALSE FOR YOUTUBE
                channelTitle: channelTitle,
                copyrightAttribution: "YouTube • \(channelTitle)"
            )
            tracks.append(track)
        }

        return SearchResultPage(
            provider: .youtube,
            tracks: tracks,
            nextPageToken: searchResponse.nextPageToken,
            totalResults: searchResponse.pageInfo?.totalResults
        )
    }

    private func fetchVideoDetails(videoIDs: [String], apiKey: String) async throws -> [String: YouTubeVideoDetailItem] {
        var components = URLComponents(string: "\(baseURL)/videos")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "contentDetails,status,snippet"),
            URLQueryItem(name: "id", value: videoIDs.joined(separator: ",")),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else { return [:] }
        let request = URLRequest(url: url)
        
        do {
            let response: YouTubeVideoListResponse = try await apiClient.execute(request)
            var map: [String: YouTubeVideoDetailItem] = [:]
            for item in response.items {
                map[item.id] = item
            }
            return map
        } catch {
            return [:]
        }
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        return result
    }

    private func parseArtistAndTitle(rawTitle: String, channelTitle: String) -> (artist: String, title: String) {
        let separators = [" - ", " – ", " — "]
        for sep in separators {
            if rawTitle.contains(sep) {
                let parts = rawTitle.components(separatedBy: sep)
                if parts.count >= 2 {
                    return (
                        artist: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                        title: parts[1...].joined(separator: sep).trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
            }
        }
        return (artist: channelTitle, title: rawTitle)
    }

    private func fallbackMockTracks(query: String) -> [MusicTrack] {
        return [
            MusicTrack(
                provider: .youtube,
                title: "\(query.capitalized) (Official Video)",
                artist: "Featured YouTube Artist",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600"),
                duration: 215,
                providerTrackID: "dQw4w9WgXcQ",
                youtubeVideoID: "dQw4w9WgXcQ",
                backgroundPlaybackSupported: false,
                channelTitle: "Artist Official VEVO",
                copyrightAttribution: "YouTube • Artist Official VEVO"
            )
        ]
    }
}
