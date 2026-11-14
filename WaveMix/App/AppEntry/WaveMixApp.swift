import SwiftUI

@main
@MainActor
struct WaveMixApp: App {
    @StateObject private var playbackService: UnifiedPlaybackService
    @AppStorage("wavemix_theme") private var isDarkMode: Bool = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var isShowingSplash: Bool = true

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
            ZStack {
                if isShowingSplash {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isShowingSplash = false
                        }
                    }
                    .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                    .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(playbackService)
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
