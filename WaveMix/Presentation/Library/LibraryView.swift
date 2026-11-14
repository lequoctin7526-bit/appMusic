import SwiftUI

/// Unified user music library with favorites, recently played, and offline indicators
public struct LibraryView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var selectedTab: Int = 0 // 0 = Favorites, 1 = Recently Played
    @State private var favorites: [MusicTrack] = []
    @State private var recentlyPlayed: [MusicTrack] = []
    @State private var isLoading: Bool = true

    private let storageService = StorageService()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Segmented Selector
                    Picker("Library Segment", selection: $selectedTab) {
                        Text("Favorites").tag(0)
                        Text("Recently Played").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Track Lists
                    if selectedTab == 0 {
                        favoritesList
                    } else {
                        recentlyPlayedList
                    }
                }
                .padding(.bottom, 80) // Miniplayer padding
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadLibraryData()
        }
    }

    private var favoritesList: some View {
        Group {
            if favorites.isEmpty {
                emptyState(title: "No Favorites Yet", subtitle: "Tap the heart icon or menu on any track to add it to your favorites.")
            } else {
                List {
                    ForEach(favorites) { track in
                        TrackRowView(
                            track: track,
                            isCurrentlyPlaying: playbackService.currentTrack?.id == track.id,
                            onSelect: {
                                playbackService.play(track: track, in: favorites)
                            },
                            onFindLicensed: {
                                playbackService.showLicensedMatchSheet = true
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var recentlyPlayedList: some View {
        Group {
            if recentlyPlayed.isEmpty {
                emptyState(title: "No History Recorded", subtitle: "Tracks you listen to will appear here.")
            } else {
                List {
                    ForEach(recentlyPlayed) { track in
                        TrackRowView(
                            track: track,
                            isCurrentlyPlaying: playbackService.currentTrack?.id == track.id,
                            onSelect: {
                                playbackService.play(track: track, in: recentlyPlayed)
                            },
                            onFindLicensed: {
                                playbackService.showLicensedMatchSheet = true
                            }
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.house")
                .font(.system(size: 48))
                .foregroundColor(WaveMixColors.textTertiary)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(WaveMixColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
    }

    private func loadLibraryData() async {
        self.favorites = (try? await storageService.getFavorites()) ?? []
        self.recentlyPlayed = (try? await storageService.getRecentlyPlayed(limit: 30)) ?? []
        self.isLoading = false
    }
}
