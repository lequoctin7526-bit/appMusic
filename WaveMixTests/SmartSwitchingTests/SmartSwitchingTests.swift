import XCTest
@testable import WaveMix

final class SmartSwitchingTests: XCTestCase {

    func testTitleCleaningRemovesFluff() {
        let switcher = SmartSourceSwitchUseCase(appleMusicSearcher: nil, licensedCatalogSearcher: nil)

        let testCases: [(input: String, channel: String, expectedArtist: String, expectedTitle: String)] = [
            ("The Weeknd - Blinding Lights (Official Video)", "The Weeknd", "The Weeknd", "Blinding Lights"),
            ("Coldplay - Yellow [Official Audio]", "Coldplay", "Coldplay", "Yellow"),
            ("Billie Eilish - bad guy (Lyrics / Lyric Video)", "Billie Eilish", "Billie Eilish", "bad guy"),
            ("Queen - Bohemian Rhapsody (HD 4K)", "Queen Official", "Queen", "Bohemian Rhapsody")
        ]

        for test in testCases {
            let res = switcher.cleanMetadata(from: test.input, channelTitle: test.channel)
            XCTAssertEqual(res.artist, test.expectedArtist, "Failed artist extraction for \(test.input)")
            XCTAssertEqual(res.title, test.expectedTitle, "Failed title extraction for \(test.input)")
        }
    }

    func testLicensedCandidateConfidenceScoring() async throws {
        let licensedTrack = MusicTrack(
            provider: .licensedCatalog,
            title: "Blinding Lights",
            artist: "The Weeknd",
            providerTrackID: "lic_test_1",
            backgroundPlaybackSupported: true
        )

        class MockLicensedSearcher: MusicSearchProvider {
            let provider: MusicProvider = .licensedCatalog
            let returnTrack: MusicTrack
            init(returnTrack: MusicTrack) { self.returnTrack = returnTrack }

            func search(query: String, filter: SearchFilter, pageToken: String?) async throws -> SearchResultPage {
                return SearchResultPage(provider: .licensedCatalog, tracks: [returnTrack], nextPageToken: nil, totalResults: 1)
            }
        }

        let switcher = SmartSourceSwitchUseCase(
            appleMusicSearcher: nil,
            licensedCatalogSearcher: MockLicensedSearcher(returnTrack: licensedTrack)
        )

        let ytTrack = MusicTrack(
            provider: .youtube,
            title: "The Weeknd - Blinding Lights (Official Music Video)",
            artist: "The Weeknd",
            providerTrackID: "yt_test_1"
        )

        let candidates = try await switcher.findLicensedVersions(for: ytTrack)
        XCTAssertFalse(candidates.isEmpty, "Should find at least one licensed candidate")
        XCTAssertGreaterThanOrEqual(candidates.first?.confidenceScore ?? 0, 0.8, "Exact match should have high confidence")
        XCTAssertTrue(candidates.first?.track.backgroundPlaybackSupported ?? false, "Candidate must support background audio")
    }
}
