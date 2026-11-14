import XCTest
@testable import WaveMix

final class PlaybackTests: XCTestCase {

    func testQueueProgressionAndRepeatModes() {
        let t1 = MusicTrack(provider: .appleMusic, title: "Track 1", artist: "Artist 1", providerTrackID: "1")
        let t2 = MusicTrack(provider: .youtube, title: "Track 2", artist: "Artist 2", providerTrackID: "2")
        let t3 = MusicTrack(provider: .licensedCatalog, title: "Track 3", artist: "Artist 3", providerTrackID: "3")

        var queue = PlaybackQueue(tracks: [t1, t2, t3], startIndex: 0)

        XCTAssertEqual(queue.currentTrack?.title, "Track 1")
        XCTAssertTrue(queue.hasNext)

        let nextTrack = queue.advanceToNext()
        XCTAssertEqual(nextTrack?.title, "Track 2")

        let thirdTrack = queue.advanceToNext()
        XCTAssertEqual(thirdTrack?.title, "Track 3")

        // In repeatMode = .off, advancing past end returns nil
        queue.repeatMode = .off
        let pastEnd = queue.advanceToNext()
        XCTAssertNil(pastEnd)

        // In repeatMode = .all, loops back to first
        queue.repeatMode = .all
        let looped = queue.advanceToNext()
        XCTAssertEqual(looped?.title, "Track 1")

        // In repeatMode = .one, stays on current
        queue.repeatMode = .one
        let repeatedOne = queue.advanceToNext()
        XCTAssertEqual(repeatedOne?.title, "Track 1")
    }

    func testMixedProviderPlaylistCapabilityCalculation() {
        let ytTrack = MusicTrack(provider: .youtube, title: "YT", artist: "Artist", providerTrackID: "yt")
        let amTrack = MusicTrack(provider: .appleMusic, title: "AM", artist: "Artist", providerTrackID: "am")
        let licTrack = MusicTrack(provider: .licensedCatalog, title: "LIC", artist: "Artist", providerTrackID: "lic")

        let mixedPlaylist = MusicPlaylist(
            title: "Mixed Mix",
            tracks: [ytTrack, amTrack, licTrack]
        )

        XCTAssertFalse(mixedPlaylist.isFullyBackgroundCapable, "Mixed playlist containing YouTube must not be fully background capable")
        XCTAssertEqual(mixedPlaylist.backgroundPlayableTrackCount, 2, "Only Apple Music and Licensed tracks support background audio")
        XCTAssertEqual(mixedPlaylist.containedProviders.count, 3)

        let licensedOnlyPlaylist = MusicPlaylist(
            title: "Licensed Only",
            tracks: [amTrack, licTrack]
        )
        XCTAssertTrue(licensedOnlyPlaylist.isFullyBackgroundCapable)
    }

    func testShufflePreservesCurrentTrack() {
        let t1 = MusicTrack(provider: .appleMusic, title: "Track 1", artist: "Artist 1", providerTrackID: "1")
        let t2 = MusicTrack(provider: .youtube, title: "Track 2", artist: "Artist 2", providerTrackID: "2")
        let t3 = MusicTrack(provider: .licensedCatalog, title: "Track 3", artist: "Artist 3", providerTrackID: "3")

        var queue = PlaybackQueue(tracks: [t1, t2, t3], startIndex: 1)
        XCTAssertEqual(queue.currentTrack?.title, "Track 2")

        queue.isShuffled = true
        // Current track must remain Track 2 after shuffle
        XCTAssertEqual(queue.currentTrack?.title, "Track 2")
        XCTAssertEqual(queue.currentTracks.count, 3)
    }
}
