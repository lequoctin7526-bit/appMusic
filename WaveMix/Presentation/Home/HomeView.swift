import SwiftUI

/// Home Screen – Vietnam Edition
/// Showcasing Trending Vietnam YouTube music, V-Pop, Rap Việt, Indie, Bolero, and multi-source library
public struct HomeView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var trendingVietnam: [MusicTrack] = []
    @State private var vpopTracks: [MusicTrack] = []
    @State private var rapVietTracks: [MusicTrack] = []
    @State private var indieVietTracks: [MusicTrack] = []
    @State private var boleroTracks: [MusicTrack] = []
    @State private var recentlyPlayed: [MusicTrack] = []
    @State private var playlists: [MusicPlaylist] = []
    @State private var isLoading: Bool = true

    private let storageService = StorageService()
    private let youtubeService: YouTubeAPIService

    public init() {
        self.youtubeService = AppDependencyContainer.shared.youtubeAPIService
    }

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.midnightBlack.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        // User Greeting & Brand Hero Banner
                        heroSection

                        // Trending in Vietnam (Section 8)
                        horizontalSection(
                            title: "Trending tại Việt Nam",
                            subtitle: "Bảng xếp hạng video âm nhạc thịnh hành nhất",
                            provider: .youtube,
                            tracks: trendingVietnam
                        )

                        // V-Pop Nổi Bật (Section 7 & 11)
                        if !vpopTracks.isEmpty {
                            horizontalSection(
                                title: "V-Pop Nổi Bật",
                                subtitle: "Những bản hit V-Pop đang khuấy đảo mạng xã hội",
                                provider: .youtube,
                                tracks: vpopTracks
                            )
                        }

                        // Rap Việt
                        if !rapVietTracks.isEmpty {
                            horizontalSection(
                                title: "Rap Việt Thịnh Hành",
                                subtitle: "Âm hưởng đường phố & flow đỉnh cao từ nghệ sĩ Việt",
                                provider: .youtube,
                                tracks: rapVietTracks
                            )
                        }

                        // Indie & Chill Việt
                        if !indieVietTracks.isEmpty {
                            horizontalSection(
                                title: "Indie Việt & Acoustic",
                                subtitle: "Giai điệu mộc mạc, sâu lắng và tự do",
                                provider: .youtube,
                                tracks: indieVietTracks
                            )
                        }

                        // Bolero & Nhạc Trữ Tình
                        if !boleroTracks.isEmpty {
                            horizontalSection(
                                title: "Bolero & Trữ Tình",
                                subtitle: "Những tình khúc quê hương đi cùng năm tháng",
                                provider: .youtube,
                                tracks: boleroTracks
                            )
                        }

                        // Recently Played
                        if !recentlyPlayed.isEmpty {
                            horizontalSection(
                                title: "Nghe Gần Đây",
                                subtitle: "Tiếp tục giai điệu yêu thích của bạn",
                                tracks: recentlyPlayed
                            )
                        }

                        // User Playlists
                        playlistsSection
                    }
                    .padding(.bottom, 90) // Pad for docked mini player
                }
            }
            .navigationTitle("WaveMix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        WaveMixLogoView(size: 26, isPulsing: false, showWordmark: false)
                        Text("WaveMix")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(WaveMixColors.neonAccentGradient)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe.asia.australia.fill")
                            .font(.system(size: 11))
                            .foregroundColor(WaveMixColors.neonCyan)
                        Text("VN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(WaveMixColors.neonCyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(WaveMixColors.surfaceElevated)
                    .cornerRadius(8)
                }
            }
        }
        .task {
            await loadHomeData()
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            WaveMixColors.deepPurple.opacity(0.85),
                            WaveMixColors.surfaceDark
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(WaveMixColors.neonCyan)
                        Text("VIETNAM MUSIC DISCOVERY")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(WaveMixColors.neonCyan)
                    }

                    Text("Feel Every Beat.\nDiscover Every Song.")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text("Khám phá MV YouTube thịnh hành và chuyển nguồn phát studio bản quyền để nghe nhạc khi tắt màn hình.")
                        .font(.system(size: 12))
                        .foregroundColor(WaveMixColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                WaveMixLogoView(size: 64, isPulsing: true, showWordmark: false)
                    .padding(.trailing, 8)
            }
            .padding(20)
        }
        .frame(height: 165)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Horizontal Section

    private func horizontalSection(
        title: String,
        subtitle: String? = nil,
        provider: MusicProvider? = nil,
        tracks: [MusicTrack]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(WaveMixColors.textPrimary)

                    Spacer()

                    if let provider = provider {
                        ProviderBadgeView(provider: provider)
                    }
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(WaveMixColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(tracks) { track in
                        Button(action: {
                            playbackService.play(track: track, in: tracks)
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .bottomTrailing) {
                                    AsyncArtworkView(url: track.artworkURL, provider: track.provider, cornerRadius: 12)
                                        .frame(width: 136, height: 136)

                                    ProviderBadgeView(
                                        provider: track.provider,
                                        showCapability: false,
                                        isVietnameseChannel: track.isVietnameseChannel
                                    )
                                    .padding(6)
                                }

                                Text(track.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(WaveMixColors.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 136, alignment: .leading)

                                Text(track.artist)
                                    .font(.system(size: 11))
                                    .foregroundColor(WaveMixColors.textSecondary)
                                    .lineLimit(1)
                                    .frame(width: 136, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Playlists Section

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danh Sách Phát Của Bạn")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(playlists) { playlist in
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(WaveMixColors.surfaceElevated)
                                    .frame(width: 150, height: 100)

                                Image(systemName: "music.note.list")
                                    .font(.system(size: 32))
                                    .foregroundColor(WaveMixColors.deepPurple)
                            }

                            Text(playlist.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(WaveMixColors.textPrimary)
                                .lineLimit(1)
                                .frame(width: 150, alignment: .leading)

                            Text("\(playlist.tracks.count) bài hát")
                                .font(.system(size: 11))
                                .foregroundColor(WaveMixColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Data Loading

    private func loadHomeData() async {
        self.recentlyPlayed = (try? await storageService.getRecentlyPlayed(limit: 10)) ?? []
        self.playlists = (try? await storageService.getAllPlaylists()) ?? []

        // 1. Fetch real Trending Vietnam from YouTube Data API
        self.trendingVietnam = (try? await youtubeService.fetchTrendingVietnam(limit: 20)) ?? []

        // 2. Fetch Vietnam Categories
        self.vpopTracks = (try? await youtubeService.fetchCategoryTracks(category: .vpop, limit: 12)) ?? []
        self.rapVietTracks = (try? await youtubeService.fetchCategoryTracks(category: .rapViet, limit: 12)) ?? []
        self.indieVietTracks = (try? await youtubeService.fetchCategoryTracks(category: .indieViet, limit: 12)) ?? []
        self.boleroTracks = (try? await youtubeService.fetchCategoryTracks(category: .bolero, limit: 12)) ?? []

        self.isLoading = false
    }
}
