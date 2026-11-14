import SwiftUI

@main
@MainActor
struct WaveMixApp: App {
    @StateObject private var playbackService: UnifiedPlaybackService
    @AppStorage("wavemix_theme") private var isDarkMode: Bool = true

    init() {
        let container = AppDependencyContainer.shared
        let controller = YouTubePlayerController()
        let service = UnifiedPlaybackService(
            youtubeController: controller,
            appleMusicService: container.appleMusicService,
            licensedCatalogService: container.licensedCatalogService,
            audioSessionService: container.audioSessionService,
            nowPlayingService: container.nowPlayingService,
            mediaRemoteService: container.mediaRemoteService,
            storageService: container.storageService
        )
        _playbackService = StateObject(wrappedValue: service)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(playbackService)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
