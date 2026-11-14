import SwiftUI

/// Premium Home Screen showcasing curated and trending music across multiple providers
public struct HomeView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var trendingYouTube: [MusicTrack] = []
    @State private var appleRecommendations: [MusicTrack] = []
    @State private var licensedCatalogTracks: [MusicTrack] = []
    @State private var recentlyPlayed: [MusicTrack] = []
    @State private var playlists: [MusicPlaylist] = []
    @State private var isLoading: Bool = true

    private let storageService = StorageService()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        // Header / Hero Section
                        heroSection

                        // Recently Played (if any)
                        if !recentlyPlayed.isEmpty {
                            horizontalSection(title: "Recently Played", tracks: recentlyPlayed)
                        }

                        // YouTube Music Videos (Foreground visual discovery)
                        horizontalSection(
                            title: "Trending on YouTube",
                            subtitle: "Official music videos & live performances",
                            provider: .youtube,
                            tracks: trendingYouTube
                        )

                        // Apple Music Recommendations
                        horizontalSection(
                            title: "Apple Music Recommendations",
                            subtitle: "Studio quality • Background listening enabled",
                            provider: .appleMusic,
                            tracks: appleRecommendations
                        )

                        // Licensed Direct Catalog
                        horizontalSection(
                            title: "Licensed WaveMix Originals",
                            subtitle: "Direct partner rights • Unrestricted streaming",
                            provider: .licensedCatalog,
                            tracks: licensedCatalogTracks
                        )

                        // Curated Playlists
                        playlistsSection
                    }
                    .padding(.bottom, 90) // Pad for mini player
                }
            }
            .navigationTitle("WaveMix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(WaveMixColors.brandGradient)
                            .font(.system(size: 18, weight: .bold))
                        Text("WaveMix")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadHomeData()
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [WaveMixColors.accentViolet.opacity(0.8), WaveMixColors.surfaceDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(WaveMixColors.accentCyan)
                    Text("MULTI-SOURCE DISCOVERY")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(WaveMixColors.accentCyan)
                }

                Text("Discover on YouTube.\nStream with Screen Off.")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text("Find your favorite tracks and seamlessly switch to licensed studio versions for background listening.")
                    .font(.system(size: 12))
                    .foregroundColor(WaveMixColors.textSecondary)
                    .lineLimit(2)
            }
            .padding(20)
        }
        .frame(height: 160)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

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

                                    ProviderBadgeView(provider: track.provider, showCapability: false)
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

    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Playlists")
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
                                    .foregroundColor(WaveMixColors.accentViolet)
                            }

                            Text(playlist.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(WaveMixColors.textPrimary)
                                .lineLimit(1)
                                .frame(width: 150, alignment: .leading)

                            Text("\(playlist.tracks.count) tracks")
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
        // Load recent tracks and playlists
        self.recentlyPlayed = (try? await storageService.getRecentlyPlayed(limit: 10)) ?? []
        self.playlists = (try? await storageService.getAllPlaylists()) ?? []

        // Seed rich trending tracks for each provider
        self.trendingYouTube = [
            MusicTrack(
                provider: .youtube,
                title: "As It Was",
                artist: "Harry Styles",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600"),
                duration: 167,
                providerTrackID: "H5v3kku4y6Q",
                youtubeVideoID: "H5v3kku4y6Q",
                backgroundPlaybackSupported: false,
                channelTitle: "HarryStylesVEVO",
                copyrightAttribution: "YouTube • HarryStylesVEVO"
            ),
            MusicTrack(
                provider: .youtube,
                title: "Flowers",
                artist: "Miley Cyrus",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600"),
                duration: 200,
                providerTrackID: "G7KNmW9a75Y",
                youtubeVideoID: "G7KNmW9a75Y",
                backgroundPlaybackSupported: false,
                channelTitle: "MileyCyrusVEVO",
                copyrightAttribution: "YouTube • MileyCyrusVEVO"
            ),
            MusicTrack(
                provider: .youtube,
                title: "Blinding Lights",
                artist: "The Weeknd",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600"),
                duration: 260,
                providerTrackID: "4NRXx6U8ABQ",
                youtubeVideoID: "4NRXx6U8ABQ",
                backgroundPlaybackSupported: false,
                channelTitle: "TheWeekndVEVO",
                copyrightAttribution: "YouTube • TheWeekndVEVO"
            )
        ]

        self.appleRecommendations = [
            MusicTrack(
                provider: .appleMusic,
                title: "Anti-Hero",
                artist: "Taylor Swift",
                album: "Midnights",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600"),
                duration: 201,
                providerTrackID: "am_anti_hero",
                appleMusicID: "am_anti_hero",
                isExplicit: false,
                backgroundPlaybackSupported: true,
                copyrightAttribution: "Apple Music Catalog"
            ),
            MusicTrack(
                provider: .appleMusic,
                title: "Stay",
                artist: "The Kid LAROI & Justin Bieber",
                album: "F*CK LOVE 3+: OVER YOU",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600"),
                duration: 141,
                providerTrackID: "am_stay",
                appleMusicID: "am_stay",
                isExplicit: true,
                backgroundPlaybackSupported: true,
                copyrightAttribution: "Apple Music Catalog"
            )
        ]

        self.licensedCatalogTracks = [
            MusicTrack(
                provider: .licensedCatalog,
                title: "Neon Horizon",
                artist: "Synthwave Collective",
                album: "Cyber Dreams 2026",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=600"),
                duration: 232,
                providerTrackID: "lic_neon_01",
                backgroundPlaybackSupported: true,
                copyrightAttribution: "Licensed directly to WaveMix",
                streamURL: URL(string: "https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Sevish_-__nbsp_.mp3")
            ),
            MusicTrack(
                provider: .licensedCatalog,
                title: "Solar Wind",
                artist: "Aurora Borealis",
                album: "Deep Ambient Volume II",
                artworkURL: URL(string: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600"),
                duration: 310,
                providerTrackID: "lic_solar_02",
                backgroundPlaybackSupported: true,
                copyrightAttribution: "Licensed directly to WaveMix",
                streamURL: URL(string: "https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Sevish_-__nbsp_.mp3")
            )
        ]

        self.isLoading = false
    }
}
