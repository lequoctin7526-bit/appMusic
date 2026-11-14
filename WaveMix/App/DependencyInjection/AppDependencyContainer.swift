import Foundation

/// Dependency container wiring all services, repositories, and use cases
public final class AppDependencyContainer: @unchecked Sendable {
    public static let shared = AppDependencyContainer()

    public let storageService: StorageService
    public let audioSessionService: AudioSessionService
    public let nowPlayingService: NowPlayingService
    public let mediaRemoteService: MediaRemoteService
    public let backgroundAudioService: BackgroundAudioService
    public let youtubeAPIService: YouTubeAPIService
    public let appleMusicService: AppleMusicService
    public let licensedCatalogService: LicensedCatalogService
    public let localLibraryService: LocalLibraryService
    public let searchMusicUseCase: SearchMusicUseCase
    public let smartSourceSwitchUseCase: SmartSourceSwitchUseCase

    private init() {
        self.storageService = StorageService()
        self.audioSessionService = AudioSessionService()
        self.nowPlayingService = NowPlayingService()
        self.mediaRemoteService = MediaRemoteService()
        self.backgroundAudioService = BackgroundAudioService()

        // Read YouTube API key securely from Config
        self.youtubeAPIService = YouTubeAPIService {
            AppConfig.shared.youtubeAPIKey
        }
        self.appleMusicService = AppleMusicService()
        self.licensedCatalogService = LicensedCatalogService()
        self.localLibraryService = LocalLibraryService()

        self.searchMusicUseCase = SearchMusicUseCase(providers: [
            .youtube: youtubeAPIService,
            .appleMusic: appleMusicService,
            .licensedCatalog: licensedCatalogService,
            .localLibrary: localLibraryService
        ])

        self.smartSourceSwitchUseCase = SmartSourceSwitchUseCase(
            appleMusicSearcher: appleMusicService,
            licensedCatalogSearcher: licensedCatalogService
        )
    }
}
