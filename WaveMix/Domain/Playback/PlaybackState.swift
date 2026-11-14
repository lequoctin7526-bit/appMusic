import Foundation

/// Repeat mode for playback queue
public enum RepeatMode: String, Codable, CaseIterable, Sendable {
    case off
    case all
    case one

    public var systemIcon: String {
        switch self {
        case .off:
            return "repeat"
        case .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }
}

/// Comprehensive state of the unified playback engine
public enum PlaybackState: Equatable, Sendable {
    case idle
    case loading(track: MusicTrack)
    case playing(track: MusicTrack)
    case paused(track: MusicTrack)
    case stopped
    /// Special state when next item in queue is YouTube but application is currently backgrounded
    case waitingForForeground(track: MusicTrack, reason: String)
    case failed(error: String, track: MusicTrack?)

    public var currentTrack: MusicTrack? {
        switch self {
        case .idle, .stopped:
            return nil
        case .loading(let track),
             .playing(let track),
             .paused(let track),
             .waitingForForeground(let track, _):
            return track
        case .failed(_, let track):
            return track
        }
    }

    public var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var isWaitingForForeground: Bool {
        if case .waitingForForeground = self { return true }
        return false
    }
}
