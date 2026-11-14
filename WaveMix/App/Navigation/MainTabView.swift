import SwiftUI

/// Main 5-tab navigation host with persistent MiniPlayer and sheet presenter
public struct MainTabView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                SearchView()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(1)

                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }
                    .tag(2)

                PlaylistListView()
                    .tabItem {
                        Label("Playlists", systemImage: "music.note.list")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .tint(WaveMixColors.accentCyan)

            // Docked MiniPlayer floating above tab bar
            if playbackService.currentTrack != nil {
                MiniPlayerView()
                    .padding(.bottom, 54) // Position above native tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $playbackService.isMiniPlayerExpanded) {
            FullPlayerView()
                .environmentObject(playbackService)
        }
    }
}
