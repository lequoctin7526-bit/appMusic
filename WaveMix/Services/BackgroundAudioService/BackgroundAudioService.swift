import Foundation
import UIKit

/// Coordinates background execution tasks and life cycle transitions
public final class BackgroundAudioService: @unchecked Sendable {
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    public init() {}

    public func beginBackgroundTask() {
        endBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "WaveMixBackgroundAudio") { [weak self] in
            self?.endBackgroundTask()
        }
    }

    public func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
