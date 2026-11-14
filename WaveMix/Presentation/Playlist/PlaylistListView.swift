import SwiftUI

/// Playlist overview and creation screen
public struct PlaylistListView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var playlists: [MusicPlaylist] = []
    @State private var showCreateModal: Bool = false
    @State private var newPlaylistTitle: String = ""
    @State private var newPlaylistDescription: String = ""

    private let storageService = StorageService()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                if playlists.isEmpty {
                    emptyPlaylistsView
                } else {
                    List {
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                playlistRow(playlist: playlist)
                            }
                            .listRowBackground(WaveMixColors.surfaceDark)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                    .listStyle(.plain)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateModal = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(WaveMixColors.accentCyan)
                    }
                }
            }
            .sheet(isPresented: $showCreateModal) {
                createPlaylistSheet
            }
        }
        .task {
            await loadPlaylists()
        }
    }

    private func playlistRow(playlist: MusicPlaylist) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(WaveMixColors.surfaceElevated)
                    .frame(width: 56, height: 56)

                Image(systemName: "music.note.list")
                    .font(.system(size: 24))
                    .foregroundColor(WaveMixColors.accentViolet)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(WaveMixColors.textPrimary)

                HStack(spacing: 6) {
                    Text("\(playlist.tracks.count) tracks")
                        .font(.system(size: 12))
                        .foregroundColor(WaveMixColors.textSecondary)

                    // Provider count indicators
                    ForEach(playlist.containedProviders) { p in
                        Image(systemName: p.systemIcon)
                            .font(.system(size: 9))
                            .foregroundColor(p.brandColor)
                    }
                }
            }

            Spacer()

            if playlist.isFullyBackgroundCapable {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.green)
                    .help("All tracks support background playback")
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyPlaylistsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(WaveMixColors.textTertiary)
            Text("No Playlists Created")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
            Text("Create custom playlists combining tracks from YouTube, Apple Music, and Licensed Catalog.")
                .font(.system(size: 13))
                .foregroundColor(WaveMixColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button("Create First Playlist") {
                showCreateModal = true
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(WaveMixColors.brandGradient)
            .cornerRadius(12)
            .padding(.top, 8)

            Spacer()
        }
    }

    private var createPlaylistSheet: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PLAYLIST NAME")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(WaveMixColors.textTertiary)

                        TextField("e.g., Summer Roadtrip 2026", text: $newPlaylistTitle)
                            .padding(12)
                            .background(WaveMixColors.surfaceDark)
                            .cornerRadius(10)
                            .foregroundColor(.white)

                        Text("DESCRIPTION (OPTIONAL)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(WaveMixColors.textTertiary)
                            .padding(.top, 8)

                        TextField("A blend of YouTube live mixes & studio masters", text: $newPlaylistDescription)
                            .padding(12)
                            .background(WaveMixColors.surfaceDark)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Spacer()
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showCreateModal = false }
                        .foregroundColor(WaveMixColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            let created = try? await storageService.createPlaylist(
                                title: newPlaylistTitle,
                                description: newPlaylistDescription
                            )
                            if let created = created {
                                self.playlists.insert(created, at: 0)
                            }
                            self.newPlaylistTitle = ""
                            self.newPlaylistDescription = ""
                            self.showCreateModal = false
                        }
                    }
                    .disabled(newPlaylistTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(WaveMixColors.accentCyan)
                }
            }
        }
    }

    private func loadPlaylists() async {
        self.playlists = (try? await storageService.getAllPlaylists()) ?? []
    }

    private func deletePlaylists(at offsets: IndexSet) {
        for index in offsets {
            let p = playlists[index]
            Task {
                try? await storageService.deletePlaylist(id: p.id)
            }
        }
        playlists.remove(atOffsets: offsets)
    }
}
