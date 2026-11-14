import Foundation
import SwiftUI

/// Defines all supported audio and audiovisual providers in WaveMix.
/// Each provider has distinct capabilities, terms of service, and playback rules.
public enum MusicProvider: String, Codable, CaseIterable, Identifiable, Sendable {
    case youtube = "youtube"
    case appleMusic = "apple_music"
    case licensedCatalog = "licensed_catalog"
    case localLibrary = "local_library"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .youtube:
            return "YouTube"
        case .appleMusic:
            return "Apple Music"
        case .licensedCatalog:
            return "Licensed Catalog"
        case .localLibrary:
            return "Local Library"
        }
    }

    public var shortName: String {
        switch self {
        case .youtube:
            return "YT"
        case .appleMusic:
            return "Apple"
        case .licensedCatalog:
            return "Licensed"
        case .localLibrary:
            return "Local"
        }
    }

    public var systemIcon: String {
        switch self {
        case .youtube:
            return "play.rectangle.fill"
        case .appleMusic:
            return "music.note"
        case .licensedCatalog:
            return "shield.checkerboard"
        case .localLibrary:
            return "folder.fill"
        }
    }

    public var brandColor: Color {
        switch self {
        case .youtube:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // YouTube Red
        case .appleMusic:
            return Color(red: 0.98, green: 0.18, blue: 0.38) // Apple Music Pink
        case .licensedCatalog:
            return Color(red: 0.0, green: 0.78, blue: 0.65) // Emerald Cyan
        case .localLibrary:
            return Color(red: 0.55, green: 0.60, blue: 0.68) // Slate Gray
        }
    }

    /// Indicates whether this provider is legally licensed for background/lock-screen audio.
    /// YouTube is strictly foreground-only under YouTube Developer Terms §II.F.
    public var supportsBackgroundAudio: Bool {
        switch self {
        case .youtube:
            return false
        case .appleMusic, .licensedCatalog, .localLibrary:
            return true
        }
    }
}
