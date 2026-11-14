import SwiftUI
import Combine

/// Multi-source search screen with debounce, provider filtering, history, and separate attributions
public struct SearchView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var searchText: String = ""
    @State private var selectedProviderFilter: MusicProvider? = nil
    @State private var searchResults: [MusicTrack] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchHistory: [String] = []

    private let storageService = StorageService()
    private let searchUseCase: SearchMusicUseCase

    public init() {
        let youtube = YouTubeAPIService()
        let apple = AppleMusicService()
        let licensed = LicensedCatalogService()
        let local = LocalLibraryService()

        self.searchUseCase = SearchMusicUseCase(providers: [
            .youtube: youtube,
            .appleMusic: apple,
            .licensedCatalog: licensed,
            .localLibrary: local
        ])
    }

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Search Bar
                    searchBarView

                    // Provider Filter Pills
                    filterPillsView

                    // Content Area
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(WaveMixColors.accentCyan)
                        Text("Searching all music sources...")
                            .font(.system(size: 13))
                            .foregroundColor(WaveMixColors.textSecondary)
                        Spacer()
                    } else if let error = errorMessage {
                        errorStateView(error)
                    } else if searchText.isEmpty {
                        historySection
                    } else if searchResults.isEmpty {
                        emptyStateView
                    } else {
                        resultsListView
                    }
                }
                .padding(.bottom, 80) // Miniplayer offset
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            self.searchHistory = storageService.getSearchHistory()
        }
    }

    // MARK: - Subviews

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(WaveMixColors.textTertiary)

            TextField("Search songs, artists, videos...", text: $searchText)
                .foregroundColor(WaveMixColors.textPrimary)
                .font(.system(size: 15))
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(WaveMixColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(WaveMixColors.surfaceDark)
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var filterPillsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" filter pill
                filterPill(title: "All Sources", isSelected: selectedProviderFilter == nil) {
                    selectedProviderFilter = nil
                    if !searchText.isEmpty { performSearch() }
                }

                // Individual provider pills
                ForEach(MusicProvider.allCases) { provider in
                    filterPill(
                        title: provider.displayName,
                        isSelected: selectedProviderFilter == provider,
                        icon: provider.systemIcon,
                        color: provider.brandColor
                    ) {
                        selectedProviderFilter = provider
                        if !searchText.isEmpty { performSearch() }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func filterPill(
        title: String,
        isSelected: Bool,
        icon: String? = nil,
        color: Color = WaveMixColors.accentCyan,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : WaveMixColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? WaveMixColors.brandGradient : LinearGradient(colors: [WaveMixColors.surfaceElevated], startPoint: .top, endPoint: .bottom))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : WaveMixColors.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !searchHistory.isEmpty {
                HStack {
                    Text("Recent Searches")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(WaveMixColors.textPrimary)

                    Spacer()

                    Button("Clear") {
                        storageService.clearSearchHistory()
                        searchHistory = []
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(WaveMixColors.accentViolet)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(searchHistory, id: \.self) { item in
                            Button(action: {
                                searchText = item
                                performSearch()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 11))
                                    Text(item)
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(WaveMixColors.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(WaveMixColors.surfaceElevated)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }

            Spacer()
        }
    }

    private var resultsListView: some View {
        List {
            ForEach(searchResults) { track in
                TrackRowView(
                    track: track,
                    isCurrentlyPlaying: playbackService.currentTrack?.id == track.id,
                    onSelect: {
                        playbackService.play(track: track, in: searchResults)
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

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundColor(WaveMixColors.textTertiary)
            Text("No results found for \"\(searchText)\"")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(WaveMixColors.textSecondary)
            Text("Try searching by track name, artist, or changing the source filter.")
                .font(.system(size: 12))
                .foregroundColor(WaveMixColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func errorStateView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.orange)
            Text("Search Error")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(WaveMixColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry Search") {
                performSearch()
            }
            .foregroundColor(WaveMixColors.accentCyan)
            .padding(.top, 4)
            Spacer()
        }
    }

    // MARK: - Search Execution

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        storageService.addSearchHistory(query: query)
        self.searchHistory = storageService.getSearchHistory()

        isLoading = true
        errorMessage = nil

        let filter = SearchFilter(provider: selectedProviderFilter, category: .all, limit: 20)

        Task {
            do {
                let map = try await searchUseCase.search(query: query, filter: filter)
                var combined: [MusicTrack] = []
                for (_, page) in map {
                    combined.append(contentsOf: page.tracks)
                }
                await MainActor.run {
                    self.searchResults = combined
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
