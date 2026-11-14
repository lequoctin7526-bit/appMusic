import Foundation
import MediaPlayer

/// Delegate for handling hardware and lock screen remote media controls
public protocol MediaRemoteServiceDelegate: AnyObject {
    func remotePlay()
    func remotePause()
    func remoteNext()
    func remotePrevious()
    func remoteSeek(to seconds: TimeInterval)
}

/// Bridges iOS Lock Screen, Control Center, and headphone hardware buttons
public final class MediaRemoteService: @unchecked Sendable {
    public weak var delegate: MediaRemoteServiceDelegate?

    private let commandCenter = MPRemoteCommandCenter.shared()

    public init() {
        setupRemoteCommands()
    }

    private func setupRemoteCommands() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.delegate?.remotePlay()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.delegate?.remotePause()
            return .success
        }

        commandCenter.togglePlayPauseMusicCommand.isEnabled = true
        commandCenter.togglePlayPauseMusicCommand.addTarget { [weak self] _ in
            self?.delegate?.remotePlay()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.delegate?.remoteNext()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.delegate?.remotePrevious()
            return .success
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.delegate?.remoteSeek(to: positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
    }

    /// Disables remote commands when YouTube or non-background media is playing
    public func setRemoteCommandsEnabled(_ enabled: Bool) {
        commandCenter.playCommand.isEnabled = enabled
        commandCenter.pauseCommand.isEnabled = enabled
        commandCenter.nextTrackCommand.isEnabled = enabled
        commandCenter.previousTrackCommand.isEnabled = enabled
        commandCenter.changePlaybackPositionCommand.isEnabled = enabled
    }
}
