import Foundation

/// Centralized configuration provider for API keys, endpoints, localization, and regional settings
public final class AppConfig: @unchecked Sendable {
    public static let shared = AppConfig()

    private init() {}

    // MARK: - Regional Defaults (Vietnam Default Configuration)
    public let defaultRegionCode = "VN"
    public let defaultLanguage = "vi"
    public let defaultLocale = "vi_VN"
    public let defaultTimezone = "Asia/Ho_Chi_Minh"

    /// Active Region Code (defaults to "VN")
    public var activeRegionCode: String {
        UserDefaults.standard.string(forKey: "user_region_code") ?? defaultRegionCode
    }

    /// Active App Language (defaults to "vi")
    public var activeLanguage: String {
        UserDefaults.standard.string(forKey: "user_language_code") ?? defaultLanguage
    }

    /// Vietnam standard date formatter: dd/MM/yyyy
    public var standardDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "dd/MM/yyyy"
        df.locale = Locale(identifier: defaultLocale)
        df.timeZone = TimeZone(identifier: defaultTimezone)
        return df
    }

    // MARK: - YouTube API Configuration

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

    // MARK: - Licensed Catalog & App Identifiers

    /// Licensed Catalog Gateway Base URL
    public var licensedCatalogBaseURL: URL {
        URL(string: "https://api.wavemix.app/v1")!
    }

    /// App Store Bundle Identifier
    public let bundleIdentifier = "com.wavemix.musicplayer"

    /// App Version
    public let appVersion = "1.0.0"
}
