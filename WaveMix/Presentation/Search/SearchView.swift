import SwiftUI
import Combine

/// Vietnam-prioritized Multi-source search screen with debounce, category filters, and history
public struct SearchView: View {
    @EnvironmentObject private var playbackService: UnifiedPlaybackService

    @State private var searchText: String = ""
    @State private var selectedProviderFilter: MusicProvider? = nil
    @State private var selectedVietnamCategory: VietnamMusicCategory? = nil
    @State private var searchResults: [MusicTrack] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searchHistory: [String] = []

    private let storageService = StorageService()
    private let searchUseCase: SearchMusicUseCase
    private let youtubeService: YouTubeAPIService

    public init() {
        let container = AppDependencyContainer.shared
        self.youtubeService = container.youtubeAPIService
        self.searchUseCase = container.searchMusicUseCase
    }

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.midnightBlack.ignoresSafeArea()

                VStack(spacing: 12) {
                    // Search Bar
                    searchBarView

                    // Vietnam Music Category Filter Pills
                    vietnamCategoryPillsView

                    // Content Area
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(WaveMixColors.neonCyan)
                        Text("Đang tìm kiếm trên các nguồn âm nhạc...")
                            .font(.system(size: 13))
                            .foregroundColor(WaveMixColors.textSecondary)
                        Spacer()
                    } else if let error = errorMessage {
                        errorStateView(error)
                    } else if searchText.isEmpty && selectedVietnamCategory == nil {
                        historySection
                    } else if searchResults.isEmpty {
                        emptyStateView
                    } else {
                        resultsListView
                    }
                }
                .padding(.bottom, 80) // Miniplayer offset
            }
            .navigationTitle("Tìm kiếm")
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

            TextField("Tìm bài hát, nghệ sĩ, MV Việt Nam...", text: $searchText)
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

    private var vietnamCategoryPillsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "Tất cả"
                filterPill(
                    title: "Tất cả",
                    isSelected: selectedVietnamCategory == nil,
                    icon: "sparkles"
                ) {
                    selectedVietnamCategory = nil
                    if !searchText.isEmpty { performSearch() }
                }

                // Vietnam Music Categories (Section 12)
                ForEach(VietnamMusicCategory.allCases) { cat in
                    filterPill(
                        title: cat.displayName,
                        isSelected: selectedVietnamCategory == cat,
                        icon: cat.systemIcon
                    ) {
                        selectedVietnamCategory = cat
                        searchText = cat.displayName
                        performCategorySearch(category: cat)
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
            .background(
                isSelected ?
                    WaveMixColors.brandGradient :
                    LinearGradient(colors: [WaveMixColors.surfaceElevated], startPoint: .top, endPoint: .bottom)
            )
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
                    Text("Tìm kiếm gần đây")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(WaveMixColors.textPrimary)

                    Spacer()

                    Button("Xóa") {
                        storageService.clearSearchHistory()
                        searchHistory = []
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(WaveMixColors.accentPink)
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

            // Quick trending suggestions
            VStack(alignment: .leading, spacing: 10) {
                Text("Gợi ý xu hướng Việt Nam")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(WaveMixColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                let trendingSuggestions = ["Sơn Tùng M-TP", "Đen Vâu", "HIEUTHUHAI", "Vũ.", "Tăng Duy Tân", "Hoàng Thùy Linh"]
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(trendingSuggestions, id: \.self) { artist in
                            Button(action: {
                                searchText = artist
                                performSearch()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                    Text(artist)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(WaveMixColors.neonCyan)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(WaveMixColors.surfaceDark)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(WaveMixColors.neonCyan.opacity(0.3), lineWidth: 1)
                                )
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
            Text("Không tìm thấy kết quả cho \"\(searchText)\"")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(WaveMixColors.textSecondary)
            Text("Hãy thử tìm kiếm với tên bài hát, nghệ sĩ hoặc thể loại khác.")
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
            Text("Lỗi tìm kiếm")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(WaveMixColors.textPrimary)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(WaveMixColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Thử lại") {
                performSearch()
            }
            .foregroundColor(WaveMixColors.neonCyan)
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

        let filter = SearchFilter(provider: selectedProviderFilter, category: .all, limit: 25)

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

    private func performCategorySearch(category: VietnamMusicCategory) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let tracks = try await youtubeService.fetchCategoryTracks(category: category, limit: 25)
                await MainActor.run {
                    self.searchResults = tracks
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
