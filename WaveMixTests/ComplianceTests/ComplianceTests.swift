import XCTest
@testable import WaveMix

final class ComplianceTests: XCTestCase {

    func testNoUnauthorizedAudioExtractionFlags() {
        // App Store Compliance: WaveMix must strictly refuse background audio for YouTube
        let providers = MusicProvider.allCases
        for provider in providers {
            let caps = ProviderCapabilities.capabilities(for: provider)
            if provider == .youtube {
                XCTAssertFalse(caps.backgroundPlayback, "YouTube Developer Terms §II.F explicitly prohibits audio backgrounding")
                XCTAssertFalse(caps.offlinePlayback, "YouTube Developer Terms §II.E prohibits local caching/downloading")
                XCTAssertTrue(caps.requiresVideoCanvas, "YouTube requires visible video presentation")
            } else {
                XCTAssertTrue(caps.backgroundPlayback, "\(provider.displayName) is licensed for background playback")
            }
        }
    }

    func testTrackInitializationEnforcesYouTubeNoBackground() {
        // Even if a caller attempts to force backgroundPlaybackSupported: true on a YouTube track, it must be rejected
        let track = MusicTrack(
            provider: .youtube,
            title: "Test",
            artist: "Test",
            providerTrackID: "123",
            backgroundPlaybackSupported: true // Intentionally illegal parameter
        )

        XCTAssertFalse(track.backgroundPlaybackSupported, "MusicTrack constructor must strictly enforce backgroundPlaybackSupported == false for YouTube")
    }
}
