import Foundation

/// Explicit declaration of provider capabilities to strictly avoid unauthorized actions.
public struct ProviderCapabilities: Equatable, Codable, Sendable {
    public let foregroundPlayback: Bool
    public let backgroundPlayback: Bool
    public let offlinePlayback: Bool
    public let playlistSupport: Bool
    public let searchSupport: Bool
    public let requiresVideoCanvas: Bool
    public let requiresSubscription: Bool
    public let maximumBitrateKbps: Int

    public init(
        foregroundPlayback: Bool,
        backgroundPlayback: Bool,
        offlinePlayback: Bool,
        playlistSupport: Bool,
        searchSupport: Bool,
        requiresVideoCanvas: Bool,
        requiresSubscription: Bool,
        maximumBitrateKbps: Int
    ) {
        self.foregroundPlayback = foregroundPlayback
        self.backgroundPlayback = backgroundPlayback
        self.offlinePlayback = offlinePlayback
        self.playlistSupport = playlistSupport
        self.searchSupport = searchSupport
        self.requiresVideoCanvas = requiresVideoCanvas
        self.requiresSubscription = requiresSubscription
        self.maximumBitrateKbps = maximumBitrateKbps
    }

    /// Predefined capability matrix according to legal agreements and terms of service.
    public static func capabilities(for provider: MusicProvider) -> ProviderCapabilities {
        switch provider {
        case .youtube:
            return ProviderCapabilities(
                foregroundPlayback: true,
                backgroundPlayback: false,      // STRICT: YouTube IFrame policy
                offlinePlayback: false,         // STRICT: Caching/downloading forbidden
                playlistSupport: true,
                searchSupport: true,
                requiresVideoCanvas: true,      // Must display >= 200x200 CSS pixels
                requiresSubscription: false,
                maximumBitrateKbps: 256
            )
        case .appleMusic:
            return ProviderCapabilities(
                foregroundPlayback: true,
                backgroundPlayback: true,       // Allowed via MusicKit System/Application player
                offlinePlayback: false,         // Direct caching forbidden; managed by Music.app
                playlistSupport: true,
                searchSupport: true,
                requiresVideoCanvas: false,
                requiresSubscription: true,     // Requires Apple Music active subscription
                maximumBitrateKbps: 256
            )
        case .licensedCatalog:
            return ProviderCapabilities(
                foregroundPlayback: true,
                backgroundPlayback: true,       // Contractually licensed background streaming
                offlinePlayback: true,          // If licensed with FairPlay DRM
                playlistSupport: true,
                searchSupport: true,
                requiresVideoCanvas: false,
                requiresSubscription: false,
                maximumBitrateKbps: 320
            )
        case .localLibrary:
            return ProviderCapabilities(
                foregroundPlayback: true,
                backgroundPlayback: true,
                offlinePlayback: true,
                playlistSupport: true,
                searchSupport: true,
                requiresVideoCanvas: false,
                requiresSubscription: false,
                maximumBitrateKbps: 1411
            )
        }
    }
}
