import SwiftUI
import MusicKit

/// Comprehensive application settings, account authorizations, and compliance disclosures
public struct SettingsView: View {
    @AppStorage("wavemix_theme") private var isDarkMode: Bool = true
    @AppStorage("default_search_provider") private var defaultSearchProvider: String = MusicProvider.youtube.rawValue
    @AppStorage("preferred_playback_provider") private var preferredPlaybackProvider: String = MusicProvider.appleMusic.rawValue
    @AppStorage("cross_source_search") private var crossSourceSearch: Bool = true
    @AppStorage("audio_quality") private var audioQuality: String = "High (320 kbps)"

    @State private var musicKitStatusText: String = "Checking..."
    @State private var canRequestMusicKit: Bool = false
    @State private var showClearHistoryAlert: Bool = false

    private let appleMusicService = AppleMusicService()
    private let storageService = StorageService()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.backgroundDark.ignoresSafeArea()

                Form {
                    // Preferences Section
                    Section(header: Text("General Preferences").foregroundColor(WaveMixColors.textTertiary)) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                        Toggle("Cross-Source Search", isOn: $crossSourceSearch)

                        Picker("Preferred Provider", selection: $preferredPlaybackProvider) {
                            ForEach(MusicProvider.allCases) { p in
                                Text(p.displayName).tag(p.rawValue)
                            }
                        }

                        Picker("Audio Streaming Quality", selection: $audioQuality) {
                            Text("Standard (128 kbps)").tag("Standard (128 kbps)")
                            Text("High (256/320 kbps)").tag("High (320 kbps)")
                            Text("Lossless (when available)").tag("Lossless")
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // MusicKit Integration Section
                    Section(header: Text("Apple Music Integration").foregroundColor(WaveMixColors.textTertiary)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MusicKit Status")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(musicKitStatusText)
                                    .font(.system(size: 12))
                                    .foregroundColor(WaveMixColors.textSecondary)
                            }

                            Spacer()

                            if canRequestMusicKit {
                                Button("Authorize") {
                                    Task {
                                        let status = await appleMusicService.requestAuthorization()
                                        updateMusicKitStatus(status: status)
                                    }
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(WaveMixColors.accentCyan)
                            }
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // Background Audio Capability Matrix
                    Section(header: Text("Background Audio Policy Matrix").foregroundColor(WaveMixColors.textTertiary)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WaveMix complies with Apple App Review Guidelines and YouTube Developer Terms. Background audio is only enabled for legally licensed sources.")
                                .font(.system(size: 12))
                                .foregroundColor(WaveMixColors.textSecondary)

                            Divider().background(WaveMixColors.surfaceBorder)

                            capabilityRow(
                                provider: .youtube,
                                status: "Foreground Only",
                                isSupported: false,
                                note: "YouTube Developer Terms §II.F requires visual player display."
                            )

                            capabilityRow(
                                provider: .appleMusic,
                                status: "Background Allowed",
                                isSupported: true,
                                note: "Supported via MusicKit official ApplicationMusicPlayer."
                            )

                            capabilityRow(
                                provider: .licensedCatalog,
                                status: "Background Allowed",
                                isSupported: true,
                                note: "Direct contracted streaming rights via AVPlayer."
                            )

                            capabilityRow(
                                provider: .localLibrary,
                                status: "Background Allowed",
                                isSupported: true,
                                note: "Device local audio files."
                            )
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // Privacy & History Section
                    Section(header: Text("Privacy & Storage").foregroundColor(WaveMixColors.textTertiary)) {
                        Button(action: { showClearHistoryAlert = true }) {
                            Text("Clear Search & Playback History")
                                .foregroundColor(Color.red)
                        }

                        NavigationLink("Privacy Manifest Details") {
                            privacyManifestView
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // App Information
                    Section(header: Text("About WaveMix").foregroundColor(WaveMixColors.textTertiary)) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0 (Release)")
                                .foregroundColor(WaveMixColors.textSecondary)
                        }

                        HStack {
                            Text("Architecture")
                            Spacer()
                            Text("Clean Architecture • MVVM • Swift Concurrency")
                                .foregroundColor(WaveMixColors.textSecondary)
                                .font(.system(size: 11))
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)
                }
                .scrollContentBackground(.hidden)
                .padding(.bottom, 80)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Clear History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    storageService.clearSearchHistory()
                }
            } message: {
                Text("Are you sure you want to clear your local search and playback history? This action cannot be undone.")
            }
        }
        .task {
            await checkMusicKitStatus()
        }
    }

    private func capabilityRow(provider: MusicProvider, status: String, isSupported: Bool, note: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: provider.systemIcon)
                    .foregroundColor(provider.brandColor)
                    .font(.system(size: 13))

                Text(provider.displayName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WaveMixColors.textPrimary)

                Spacer()

                Text(status)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSupported ? Color.green : Color.orange)
            }

            Text(note)
                .font(.system(size: 11))
                .foregroundColor(WaveMixColors.textTertiary)
        }
        .padding(.vertical, 2)
    }

    private var privacyManifestView: some View {
        ZStack {
            WaveMixColors.backgroundDark.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Privacy Manifest (PrivacyInfo.xcprivacy)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(WaveMixColors.textPrimary)

                    Text("WaveMix respects your privacy and complies with Apple's Privacy Manifest policy for iOS 16 and later.")
                        .font(.system(size: 13))
                        .foregroundColor(WaveMixColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Tracking Domains: None. WaveMix does not track users across third-party apps.")
                        Text("• Required Reason APIs: NSPrivacyAccessedAPICategoryUserDefaults (app preferences), NSPrivacyAccessedAPICategoryFileTimestamp (local cache management).")
                        Text("• Third-Party Data Collection: Music searches are executed directly against official provider APIs (YouTube Data API v3, Apple MusicKit) without intermediate ad-tracking proxies.")
                        Text("• No YouTube Login Stored: WaveMix does not store or proxy Google/YouTube user credentials.")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(WaveMixColors.textSecondary)
                }
                .padding(20)
            }
        }
        .navigationTitle("Privacy Manifest")
    }

    private func checkMusicKitStatus() async {
        let status = MusicAuthorization.currentStatus
        switch status {
        case .authorized:
            musicKitStatusText = "Authorized & Active"
            canRequestMusicKit = false
        case .denied:
            musicKitStatusText = "Denied in System Settings"
            canRequestMusicKit = false
        case .notDetermined:
            musicKitStatusText = "Not yet requested"
            canRequestMusicKit = true
        case .restricted:
            musicKitStatusText = "Restricted by Parental Controls"
            canRequestMusicKit = false
        @unknown default:
            musicKitStatusText = "Unknown Status"
            canRequestMusicKit = true
        }
    }

    private func updateMusicKitStatus(status: AppleMusicAccessStatus) {
        switch status {
        case .authorized(let canPlay):
            musicKitStatusText = canPlay ? "Authorized (Full Catalog Subscription)" : "Authorized (Preview Mode)"
            canRequestMusicKit = false
        case .denied:
            musicKitStatusText = "Access Denied"
            canRequestMusicKit = false
        case .restricted:
            musicKitStatusText = "Access Restricted"
            canRequestMusicKit = false
        case .notDetermined:
            musicKitStatusText = "Pending Request"
            canRequestMusicKit = true
        }
    }
}
