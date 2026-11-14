import Foundation

/// Centralized configuration provider for API keys, endpoints, and security parameters
public final class AppConfig: @unchecked Sendable {
    public static let shared = AppConfig()

    private init() {}

    /// YouTube Data API v3 Key.
    /// Loaded dynamically from Info.plist `WAVEMIX_YOUTUBE_API_KEY` or process environment.
    /// Never commit secrets to public repositories.
    public var youtubeAPIKey: String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "WAVEMIX_YOUTUBE_API_KEY") as? String,
           !key.isEmpty && !key.hasPrefix("$(") {
            return key
        }
        return ProcessInfo.processInfo.environment["WAVEMIX_YOUTUBE_API_KEY"]
    }

    /// Licensed Catalog Gateway Base URL
    public var licensedCatalogBaseURL: URL {
        URL(string: "https://api.wavemix.app/v1")!
    }

    /// App Store Bundle Identifier
    public let bundleIdentifier = "com.wavemix.musicplayer"

    /// App Version
    public let appVersion = "1.0.0"
}
