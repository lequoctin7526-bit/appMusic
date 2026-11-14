import Foundation

/// Manages the unified playlist queue across multiple providers
public struct PlaybackQueue: Equatable, Sendable {
    public private(set) var originalTracks: [MusicTrack] = []
    public private(set) var currentTracks: [MusicTrack] = []
    public private(set) var currentIndex: Int = -1
    public var isShuffled: Bool = false {
        didSet {
            applyShuffle()
        }
    }
    public var repeatMode: RepeatMode = .off

    public init(tracks: [MusicTrack] = [], startIndex: Int = 0) {
        setQueue(tracks: tracks, startIndex: startIndex)
    }

    public var currentTrack: MusicTrack? {
        guard currentIndex >= 0 && currentIndex < currentTracks.count else { return nil }
        return currentTracks[currentIndex]
    }

    public var hasNext: Bool {
        switch repeatMode {
        case .one, .all:
            return !currentTracks.isEmpty
        case .off:
            return currentIndex + 1 < currentTracks.count
        }
    }

    public var hasPrevious: Bool {
        switch repeatMode {
        case .one, .all:
            return !currentTracks.isEmpty
        case .off:
            return currentIndex > 0
        }
    }

    public mutating func setQueue(tracks: [MusicTrack], startIndex: Int = 0) {
        self.originalTracks = tracks
        self.currentTracks = tracks
        self.isShuffled = false
        if tracks.isEmpty {
            self.currentIndex = -1
        } else {
            self.currentIndex = max(0, min(startIndex, tracks.count - 1))
        }
    }

    public mutating func advanceToNext() -> MusicTrack? {
        guard !currentTracks.isEmpty else { return nil }
        
        switch repeatMode {
        case .one:
            return currentTrack
        case .all:
            currentIndex = (currentIndex + 1) % currentTracks.count
            return currentTrack
        case .off:
            if currentIndex + 1 < currentTracks.count {
                currentIndex += 1
                return currentTrack
            } else {
                return nil
            }
        }
    }

    public mutating func advanceToPrevious() -> MusicTrack? {
        guard !currentTracks.isEmpty else { return nil }

        switch repeatMode {
        case .one:
            return currentTrack
        case .all:
            currentIndex = (currentIndex - 1 + currentTracks.count) % currentTracks.count
            return currentTrack
        case .off:
            if currentIndex > 0 {
                currentIndex -= 1
                return currentTrack
            } else {
                return currentTrack
            }
        }
    }

    public mutating func jumpTo(index: Int) -> MusicTrack? {
        guard index >= 0 && index < currentTracks.count else { return nil }
        currentIndex = index
        return currentTrack
    }

    public mutating func append(track: MusicTrack) {
        originalTracks.append(track)
        currentTracks.append(track)
        if currentIndex == -1 {
            currentIndex = 0
        }
    }

    public mutating func remove(at index: Int) {
        guard index >= 0 && index < currentTracks.count else { return }
        let removedTrack = currentTracks.remove(at: index)
        if let origIndex = originalTracks.firstIndex(where: { $0.id == removedTrack.id }) {
            originalTracks.remove(at: origIndex)
        }
        if currentIndex >= currentTracks.count {
            currentIndex = currentTracks.count - 1
        }
    }

    private mutating func applyShuffle() {
        guard !originalTracks.isEmpty else { return }
        let currentItem = currentTrack
        if isShuffled {
            var shuffled = originalTracks
            shuffled.shuffle()
            if let current = currentItem, let idx = shuffled.firstIndex(where: { $0.id == current.id }) {
                shuffled.remove(at: idx)
                shuffled.insert(current, at: 0)
                currentIndex = 0
            }
            currentTracks = shuffled
        } else {
            currentTracks = originalTracks
            if let current = currentItem, let idx = currentTracks.firstIndex(where: { $0.id == current.id }) {
                currentIndex = idx
            }
        }
    }
}
