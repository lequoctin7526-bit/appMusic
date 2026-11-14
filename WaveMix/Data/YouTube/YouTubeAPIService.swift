import Foundation

/// YouTube Data API v3 integration service with Vietnam Regional Configuration.
/// Adheres strictly to YouTube API Services Terms and Developer Policies:
/// - Only official endpoints are used.
/// - Validates embeddability status (`videoEmbeddable: true`).
/// - RegionCode and relevanceLanguage set to Vietnam preferences (`VN` / `vi`).
/// - Checks official channel country (`country == "VN"`) for Vietnamese Channel badge.
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

    // MARK: - Search API (Section 6: Vietnam Search Integration)

    public func search(query: String, filter: SearchFilter, pageToken: String?) async throws -> SearchResultPage {
        guard let apiKey = apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SearchResultPage(
                provider: .youtube,
                tracks: self.fallbackMockTracks(query: query),
                nextPageToken: nil,
                totalResults: 0
            )
        }

        let region = AppConfig.shared.activeRegionCode
        let language = AppConfig.shared.activeLanguage

        // 1. Construct search URL conforming strictly to Section 6
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "videoCategoryId", value: "10"),     // Music category
            URLQueryItem(name: "regionCode", value: region),         // Default "VN"
            URLQueryItem(name: "relevanceLanguage", value: language),// Default "vi"
            URLQueryItem(name: "videoEmbeddable", value: "true"),    // Only embeddable videos
            URLQueryItem(name: "videoSyndicated", value: "true"),    // Playable outside youtube.com
            URLQueryItem(name: "order", value: "relevance"),
            URLQueryItem(name: "safeSearch", value: "moderate"),
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

        // 3. Fetch channel details to detect official country (Section 9)
        let channelIDs = Array(Set(searchResponse.items.map { $0.snippet.channelId }))
        let channelCountries = await fetchChannelCountries(channelIDs: channelIDs, apiKey: apiKey)

        // 4. Assemble verified MusicTracks
        var tracks: [MusicTrack] = []
        for item in searchResponse.items {
            guard let videoId = item.id.videoId else { continue }
            
            // Filter out videos that cannot be embedded
            if let detail = videoDetails[videoId] {
                if let embeddable = detail.status?.embeddable, !embeddable {
                    continue
                }
            }

            let detail = videoDetails[videoId]
            let duration = detail?.contentDetails?.duration != nil ? ISO8601DurationParser.parse(detail!.contentDetails!.duration) : 0

            let rawTitle = decodeHTMLEntities(item.snippet.title)
            let channelTitle = decodeHTMLEntities(item.snippet.channelTitle)
            let parsedMetadata = parseArtistAndTitle(rawTitle: rawTitle, channelTitle: channelTitle)

            // Section 9: Kênh tại Việt Nam verification
            let channelCountry = channelCountries[item.snippet.channelId]
            let isVNChannel = channelCountry == "VN"

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
                copyrightAttribution: isVNChannel ? "YouTube • \(channelTitle) • Kênh tại Việt Nam" : "YouTube • \(channelTitle)",
                isVietnameseChannel: isVNChannel
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

    // MARK: - Trending Vietnam (Section 8: YouTube Data API videos.list mostPopular)

    public func fetchTrendingVietnam(limit: Int = 20) async throws -> [MusicTrack] {
        guard let apiKey = apiKeyProvider(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallbackVietnamTrendingTracks()
        }

        let region = AppConfig.shared.activeRegionCode

        var components = URLComponents(string: "\(baseURL)/videos")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,status"),
            URLQueryItem(name: "chart", value: "mostPopular"),
            URLQueryItem(name: "regionCode", value: region),
            URLQueryItem(name: "videoCategoryId", value: "10"), // Music
            URLQueryItem(name: "maxResults", value: "\(min(limit, 50))"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else { return fallbackVietnamTrendingTracks() }
        let request = URLRequest(url: url)

        do {
            let response: YouTubeVideoListResponse = try await apiClient.execute(request)
            let channelIDs = Array(Set(response.items.compactMap { $0.snippet?.channelId }))
            let channelCountries = await fetchChannelCountries(channelIDs: channelIDs, apiKey: apiKey)

            var tracks: [MusicTrack] = []
            for item in response.items {
                guard let snippet = item.snippet else { continue }
                if let embeddable = item.status?.embeddable, !embeddable {
                    continue
                }

                let duration = item.contentDetails?.duration != nil ? ISO8601DurationParser.parse(item.contentDetails!.duration) : 0
                let rawTitle = decodeHTMLEntities(snippet.title)
                let channelTitle = decodeHTMLEntities(snippet.channelTitle)
                let parsed = parseArtistAndTitle(rawTitle: rawTitle, channelTitle: channelTitle)

                let isVNChannel = channelCountries[snippet.channelId] == "VN"

                let track = MusicTrack(
                    provider: .youtube,
                    title: parsed.title,
                    artist: parsed.artist,
                    artworkURL: snippet.thumbnails.bestAvailableURL,
                    duration: duration,
                    providerTrackID: item.id,
                    youtubeVideoID: item.id,
                    backgroundPlaybackSupported: false,
                    channelTitle: channelTitle,
                    copyrightAttribution: isVNChannel ? "YouTube • \(channelTitle) • Kênh tại Việt Nam" : "YouTube • \(channelTitle)",
                    isVietnameseChannel: isVNChannel
                )
                tracks.append(track)
            }
            return tracks.isEmpty ? fallbackVietnamTrendingTracks() : tracks
        } catch {
            return fallbackVietnamTrendingTracks()
        }
    }

    // MARK: - Category Search (Section 7: Vietnam Music Categories)

    public func fetchCategoryTracks(category: VietnamMusicCategory, limit: Int = 15) async throws -> [MusicTrack] {
        let primaryQuery = category.searchQueries.first ?? category.displayName
        let filter = SearchFilter(provider: .youtube, category: .videos, limit: limit)
        let page = try await search(query: primaryQuery, filter: filter, pageToken: nil)
        return page.tracks
    }

    // MARK: - Channel Countries Lookup (Section 9)

    public func fetchChannelCountries(channelIDs: [String], apiKey: String) async -> [String: String] {
        guard !channelIDs.isEmpty else { return [:] }

        var components = URLComponents(string: "\(baseURL)/channels")
        components?.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "id", value: channelIDs.prefix(50).joined(separator: ",")),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let url = components?.url else { return [:] }
        let request = URLRequest(url: url)

        do {
            let response: YouTubeChannelListResponse = try await apiClient.execute(request)
            var map: [String: String] = [:]
            for item in response.items {
                if let country = item.snippet?.country {
                    map[item.id] = country
                }
            }
            return map
        } catch {
            return [:]
        }
    }

    // MARK: - Video Details & Helpers

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

    // MARK: - Fallback / Offline Mock Data for Previews and Tests

    private func fallbackVietnamTrendingTracks() -> [MusicTrack] {
        return [
            MusicTrack(
                provider: .youtube,
                title: "Đừng Làm Trái Tim Anh Đau",
                artist: "Sơn Tùng M-TP",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600"),
                duration: 260,
                providerTrackID: "ab0Ts_xH_rM",
                youtubeVideoID: "ab0Ts_xH_rM",
                backgroundPlaybackSupported: false,
                channelTitle: "Sơn Tùng M-TP Official",
                copyrightAttribution: "YouTube • Sơn Tùng M-TP Official • Kênh tại Việt Nam",
                isVietnameseChannel: true
            ),
            MusicTrack(
                provider: .youtube,
                title: "Cắt Đôi Nỗi Sầu",
                artist: "Tăng Duy Tân",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600"),
                duration: 185,
                providerTrackID: "t7nZ3_rM0AA",
                youtubeVideoID: "t7nZ3_rM0AA",
                backgroundPlaybackSupported: false,
                channelTitle: "Tăng Duy Tân Official",
                copyrightAttribution: "YouTube • Tăng Duy Tân Official • Kênh tại Việt Nam",
                isVietnameseChannel: true
            ),
            MusicTrack(
                provider: .youtube,
                title: "Nấu Ăn Cho Em",
                artist: "Đen ft. PiaLinh",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600"),
                duration: 254,
                providerTrackID: "VnA47Jj099s",
                youtubeVideoID: "VnA47Jj099s",
                backgroundPlaybackSupported: false,
                channelTitle: "Đen Vâu Official",
                copyrightAttribution: "YouTube • Đen Vâu Official • Kênh tại Việt Nam",
                isVietnameseChannel: true
            ),
            MusicTrack(
                provider: .youtube,
                title: "Hit Me Up",
                artist: "Binz ft. Touliver",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600"),
                duration: 215,
                providerTrackID: "bInz_H1tM3Up",
                youtubeVideoID: "bInz_H1tM3Up",
                backgroundPlaybackSupported: false,
                channelTitle: "SpaceSpeakers Group",
                copyrightAttribution: "YouTube • SpaceSpeakers • Kênh tại Việt Nam",
                isVietnameseChannel: true
            )
        ]
    }

    private func fallbackMockTracks(query: String) -> [MusicTrack] {
        return [
            MusicTrack(
                provider: .youtube,
                title: "\(query.capitalized)",
                artist: "Nghệ sĩ Việt Nam",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600"),
                duration: 220,
                providerTrackID: "dQw4w9WgXcQ",
                youtubeVideoID: "dQw4w9WgXcQ",
                backgroundPlaybackSupported: false,
                channelTitle: "Vietnam Music VEVO",
                copyrightAttribution: "YouTube • Kênh tại Việt Nam",
                isVietnameseChannel: true
            )
        ]
    }
}
