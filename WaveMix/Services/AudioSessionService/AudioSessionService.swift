import Foundation
import AVFoundation

/// Delegate protocol for audio interruptions and route changes
public protocol AudioSessionServiceDelegate: AnyObject {
    func audioSessionDidReceiveInterruption(shouldResume: Bool)
    func audioSessionDidReceiveRouteChange(reason: AVAudioSession.RouteChangeReason)
}

/// Service managing the system AVAudioSession for licensed audio streams
public final class AudioSessionService: @unchecked Sendable {
    public weak var delegate: AudioSessionServiceDelegate?

    private var notificationObservers: [NSObjectProtocol] = []
    private let session = AVAudioSession.sharedInstance()

    public init() {
        setupObservers()
    }

    deinit {
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    /// Configures session for background-capable licensed playback
    public func activatePlaybackSession() throws {
        try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
        try session.setActive(true)
    }

    /// Deactivates session (crucial when switching to YouTube or stopping)
    public func deactivatePlaybackSession() {
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore error on deactivation
        }
    }

    private func setupObservers() {
        // Interruption handling (phone calls, Siri, alarms)
        let interruptionObs = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification: notification)
        }

        // Route change handling (headphones unplugged)
        let routeObs = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification: notification)
        }

        notificationObservers.append(contentsOf: [interruptionObs, routeObs])
    }

    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            delegate?.audioSessionDidReceiveInterruption(shouldResume: false)
        case .ended:
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                let shouldResume = options.contains(.shouldResume)
                delegate?.audioSessionDidReceiveInterruption(shouldResume: shouldResume)
            } else {
                delegate?.audioSessionDidReceiveInterruption(shouldResume: false)
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        // Pause playback if headphones/AirPods disconnected
        if reason == .oldDeviceUnavailable {
            delegate?.audioSessionDidReceiveRouteChange(reason: reason)
        }
    }
}
