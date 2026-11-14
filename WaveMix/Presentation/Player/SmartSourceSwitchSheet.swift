import SwiftUI

/// Bottom sheet presenting verified licensed matches for background listening
public struct SmartSourceSwitchSheet: View {
    public let sourceTrack: MusicTrack
    public let onSelectCandidate: (MusicTrack) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var candidates: [LicensedMatchCandidate] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    private let useCase = SmartSourceSwitchUseCase(
        appleMusicSearcher: AppleMusicService(),
        licensedCatalogSearcher: LicensedCatalogService()
    )

    public init(sourceTrack: MusicTrack, onSelectCandidate: @escaping (MusicTrack) -> Void) {
        self.sourceTrack = sourceTrack
        self.onSelectCandidate = onSelectCandidate
    }

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header explanation
                    VStack(spacing: 6) {
                        Image(systemName: "headphones.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(WaveMixColors.brandGradient)

                        Text("Switch to Background Audio")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(WaveMixColors.textPrimary)

                        Text("YouTube cannot play in the background. Choose a licensed studio version below to keep listening with your screen locked.")
                            .font(.system(size: 13))
                            .foregroundColor(WaveMixColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 12)

                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(WaveMixColors.accentCyan)
                        Text("Searching licensed catalogs...")
                            .font(.system(size: 13))
                            .foregroundColor(WaveMixColors.textSecondary)
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(WaveMixColors.textSecondary)
                        Spacer()
                    } else if candidates.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(WaveMixColors.textTertiary)
                            Text("No licensed counterpart found for this track.")
                                .font(.system(size: 14))
                                .foregroundColor(WaveMixColors.textSecondary)
                        }
                        Spacer()
                    } else {
                        List(candidates) { candidate in
                            Button(action: {
                                onSelectCandidate(candidate.track)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    AsyncArtworkView(url: candidate.track.artworkURL, provider: candidate.track.provider, cornerRadius: 8)
                                        .frame(width: 48, height: 48)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(candidate.track.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(WaveMixColors.textPrimary)

                                        Text(candidate.track.artist)
                                            .font(.system(size: 13))
                                            .foregroundColor(WaveMixColors.textSecondary)

                                        HStack(spacing: 6) {
                                            ProviderBadgeView(provider: candidate.track.provider)
                                            Text(candidate.matchReason)
                                                .font(.system(size: 10))
                                                .foregroundColor(WaveMixColors.accentCyan)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(WaveMixColors.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(WaveMixColors.surfaceDark)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Licensed Alternatives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(WaveMixColors.accentCyan)
                }
            }
        }
        .task {
            await findMatches()
        }
    }

    private func findMatches() async {
        isLoading = true
        errorMessage = nil
        do {
            let results = try await useCase.findLicensedVersions(for: sourceTrack)
            self.candidates = results
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to search licensed versions."
            self.isLoading = false
        }
    }
}
