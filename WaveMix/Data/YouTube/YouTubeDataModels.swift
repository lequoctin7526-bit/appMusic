import Foundation

// MARK: - YouTube API v3 Decodables

public struct YouTubeSearchResponse: Decodable, Sendable {
    public let kind: String
    public let etag: String
    public let nextPageToken: String?
    public let prevPageToken: String?
    public let pageInfo: YouTubePageInfo?
    public let items: [YouTubeSearchResultItem]
}

public struct YouTubePageInfo: Decodable, Sendable {
    public let totalResults: Int
    public let resultsPerPage: Int
}

public struct YouTubeSearchResultItem: Decodable, Sendable {
    public let kind: String
    public let etag: String
    public let id: YouTubeResourceID
    public let snippet: YouTubeSnippet
}

public struct YouTubeResourceID: Decodable, Sendable {
    public let kind: String?
    public let videoId: String?
    public let playlistId: String?
    public let channelId: String?
}

public struct YouTubeSnippet: Decodable, Sendable {
    public let publishedAt: String
    public let channelId: String
    public let title: String
    public let description: String
    public let thumbnails: YouTubeThumbnails
    public let channelTitle: String
    public let liveBroadcastContent: String?
}

public struct YouTubeThumbnails: Decodable, Sendable {
    public let `default`: YouTubeThumbnail?
    public let medium: YouTubeThumbnail?
    public let high: YouTubeThumbnail?
    public let standard: YouTubeThumbnail?
    public let maxres: YouTubeThumbnail?

    public var bestAvailableURL: URL? {
        if let urlStr = maxres?.url ?? high?.url ?? medium?.url ?? `default`?.url {
            return URL(string: urlStr)
        }
        return nil
    }
}

public struct YouTubeThumbnail: Decodable, Sendable {
    public let url: String
    public let width: Int?
    public let height: Int?
}

// MARK: - Video Details Response

public struct YouTubeVideoListResponse: Decodable, Sendable {
    public let items: [YouTubeVideoDetailItem]
}

public struct YouTubeVideoDetailItem: Decodable, Sendable {
    public let id: String
    public let snippet: YouTubeSnippet?
    public let contentDetails: YouTubeContentDetails?
    public let status: YouTubeVideoStatus?
}

public struct YouTubeContentDetails: Decodable, Sendable {
    public let duration: String // ISO 8601 e.g. "PT3M45S"
}

public struct YouTubeVideoStatus: Decodable, Sendable {
    public let uploadStatus: String?
    public let privacyStatus: String?
    public let license: String?
    public let embeddable: Bool?
    public let publicStatsViewable: Bool?
}

// MARK: - ISO 8601 Duration Parser

public enum ISO8601DurationParser {
    /// Parses ISO 8601 durations like "PT4M13S" or "PT1H2M30S" to TimeInterval (seconds)
    public static func parse(_ duration: String) -> TimeInterval {
        var totalSeconds: Double = 0
        let scanner = Scanner(string: duration)
        _ = scanner.scanString("PT")
        
        while !scanner.isAtEnd {
            var value: Double = 0
            if scanner.scanDouble(&value) {
                if scanner.scanString("H") != nil {
                    totalSeconds += value * 3600
                } else if scanner.scanString("M") != nil {
                    totalSeconds += value * 60
                } else if scanner.scanString("S") != nil {
                    totalSeconds += value
                }
            } else {
                _ = scanner.scanCharacter()
            }
        }
        return totalSeconds
    }
}
