import XCTest
@testable import WaveMix

final class YouTubeAPIServiceTests: XCTestCase {

    func testISO8601DurationParsing() {
        XCTAssertEqual(ISO8601DurationParser.parse("PT3M45S"), 225.0)
        XCTAssertEqual(ISO8601DurationParser.parse("PT4M13S"), 253.0)
        XCTAssertEqual(ISO8601DurationParser.parse("PT1H2M30S"), 3750.0)
        XCTAssertEqual(ISO8601DurationParser.parse("PT45S"), 45.0)
        XCTAssertEqual(ISO8601DurationParser.parse("PT10M"), 600.0)
    }

    func testYouTubeProviderStrictNoBackgroundPlayback() {
        let track = MusicTrack(
            provider: .youtube,
            title: "Shape of You",
            artist: "Ed Sheeran",
            providerTrackID: "JGwWNGJdvx8",
            youtubeVideoID: "JGwWNGJdvx8"
        )

        // Strict YouTube Developer Terms §II.F check
        XCTAssertFalse(track.backgroundPlaybackSupported, "YouTube tracks must NEVER support background playback")
    }

    func testYouTubeMetadataCleaningAndEntityDecoding() {
        let switcher = SmartSourceSwitchUseCase(appleMusicSearcher: nil, licensedCatalogSearcher: nil)
        
        let cleaned1 = switcher.cleanMetadata(
            from: "Adele - Easy On Me (Official Music Video)",
            channelTitle: "AdeleVEVO"
        )
        XCTAssertEqual(cleaned1.artist, "Adele")
        XCTAssertEqual(cleaned1.title, "Easy On Me")

        let cleaned2 = switcher.cleanMetadata(
            from: "Dua Lipa – Levitating [Official Visualizer] [4K]",
            channelTitle: "Dua Lipa"
        )
        XCTAssertEqual(cleaned2.artist, "Dua Lipa")
        XCTAssertEqual(cleaned2.title, "Levitating")
    }

    func testEmbeddabilityRequirement() {
        let caps = ProviderCapabilities.capabilities(for: .youtube)
        XCTAssertTrue(caps.requiresVideoCanvas, "YouTube requires visible video canvas")
        XCTAssertFalse(caps.backgroundPlayback, "YouTube policy forbids background playback")
        XCTAssertFalse(caps.offlinePlayback, "YouTube policy forbids offline downloading")
    }
}
