import SwiftUI
import MusicKit

/// Comprehensive application settings, regional configurations, and compliance disclosures
public struct SettingsView: View {
    // Appearance
    @AppStorage("wavemix_theme") private var isDarkMode: Bool = true
    @AppStorage("animation_effects_enabled") private var animationEffectsEnabled: Bool = true

    // Region & Language (Section 5 & 13)
    @AppStorage("user_region_code") private var userRegionCode: String = "VN"
    @AppStorage("user_language_code") private var userLanguageCode: String = "vi"

    // Music Discovery
    @AppStorage("preferred_playback_provider") private var preferredPlaybackProvider: String = MusicProvider.youtube.rawValue
    @AppStorage("prioritize_vietnam_music") private var prioritizeVietnamMusic: Bool = true
    @AppStorage("audio_quality") private var audioQuality: String = "High (320 kbps)"

    @State private var musicKitStatusText: String = "Đang kiểm tra..."
    @State private var canRequestMusicKit: Bool = false
    @State private var showClearHistoryAlert: Bool = false
    @State private var showOnboardingModal: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let appleMusicService = AppleMusicService()
    private let storageService = StorageService()

    public init() {}

    public var body: some View {
        NavigationView {
            ZStack {
                WaveMixColors.midnightBlack.ignoresSafeArea()

                Form {
                    // 1. APPEARANCE
                    Section(header: Text("Giao diện (Appearance)").foregroundColor(WaveMixColors.textTertiary)) {
                        Toggle("Chế độ tối (Dark Mode)", isOn: $isDarkMode)
                        Toggle("Hiệu ứng chuyển động (Animations)", isOn: $animationEffectsEnabled)

                        HStack {
                            Text("Giảm chuyển động hệ thống (Reduce Motion)")
                                .font(.system(size: 13))
                            Spacer()
                            Text(reduceMotion ? "Bật" : "Tắt")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(reduceMotion ? Color.orange : Color.green)
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 2. REGION & LANGUAGE (Section 5 & 13)
                    Section(header: Text("Khu vực & Ngôn ngữ").foregroundColor(WaveMixColors.textTertiary)) {
                        Picker("Quốc gia / Khu vực", selection: $userRegionCode) {
                            Text("Việt Nam (VN) 🇻🇳").tag("VN")
                            Text("Hoa Kỳ (US) 🇺🇸").tag("US")
                            Text("Toàn cầu (Global) 🌐").tag("GLOBAL")
                        }

                        Picker("Ngôn ngữ ứng dụng", selection: $userLanguageCode) {
                            Text("Tiếng Việt").tag("vi")
                            Text("English").tag("en")
                        }

                        HStack {
                            Text("Múi giờ mặc định")
                            Spacer()
                            Text("Asia/Ho_Chi_Minh (GMT+7)")
                                .font(.system(size: 12))
                                .foregroundColor(WaveMixColors.textSecondary)
                        }

                        HStack {
                            Text("Định dạng ngày")
                            Spacer()
                            Text("dd/MM/yyyy")
                                .font(.system(size: 12))
                                .foregroundColor(WaveMixColors.textSecondary)
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 3. MUSIC DISCOVERY & VIETNAM
                    Section(header: Text("Khám phá âm nhạc (Music Discovery)").foregroundColor(WaveMixColors.textTertiary)) {
                        Toggle("Ưu tiên nội dung & nghệ sĩ Việt Nam", isOn: $prioritizeVietnamMusic)

                        Picker("Nguồn phát ưa thích", selection: $preferredPlaybackProvider) {
                            ForEach(MusicProvider.allCases) { p in
                                Text(p.displayName).tag(p.rawValue)
                            }
                        }

                        Picker("Chất lượng stream audio", selection: $audioQuality) {
                            Text("Tiêu chuẩn (128 kbps)").tag("Standard (128 kbps)")
                            Text("Chất lượng cao (320 kbps)").tag("High (320 kbps)")
                            Text("Lossless (Khi có bản quyền)").tag("Lossless")
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 4. ONBOARDING & INTRO
                    Section(header: Text("Hướng dẫn & Giới thiệu").foregroundColor(WaveMixColors.textTertiary)) {
                        Button(action: { showOnboardingModal = true }) {
                            HStack {
                                Image(systemName: "sparkles.tv")
                                    .foregroundColor(WaveMixColors.neonCyan)
                                Text("Xem lại màn hình giới thiệu (Intro Onboarding)")
                                    .foregroundColor(WaveMixColors.textPrimary)
                            }
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 5. MUSICKIT INTEGRATION
                    Section(header: Text("Tích hợp Apple Music (MusicKit)").foregroundColor(WaveMixColors.textTertiary)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trạng thái MusicKit")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(musicKitStatusText)
                                    .font(.system(size: 12))
                                    .foregroundColor(WaveMixColors.textSecondary)
                            }

                            Spacer()

                            if canRequestMusicKit {
                                Button("Ủy quyền") {
                                    Task {
                                        let status = await appleMusicService.requestAuthorization()
                                        updateMusicKitStatus(status: status)
                                    }
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(WaveMixColors.neonCyan)
                            }
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 6. BACKGROUND AUDIO CAPABILITY MATRIX
                    Section(header: Text("Chính sách phát nhạc nền").foregroundColor(WaveMixColors.textTertiary)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("WaveMix tuân thủ tuyệt đối quy định của Apple App Review và YouTube Developer Terms §II.F:")
                                .font(.system(size: 12))
                                .foregroundColor(WaveMixColors.textSecondary)

                            Divider().background(WaveMixColors.surfaceBorder)

                            capabilityRow(
                                provider: .youtube,
                                status: "Mở màn hình (Foreground)",
                                isSupported: false,
                                note: "YouTube Developer Terms yêu cầu bắt buộc hiển thị player hình ảnh."
                            )

                            capabilityRow(
                                provider: .appleMusic,
                                status: "Phát nền (Background)",
                                isSupported: true,
                                note: "Hỗ trợ chính thức qua Apple MusicKit Player."
                            )

                            capabilityRow(
                                provider: .licensedCatalog,
                                status: "Phát nền (Background)",
                                isSupported: true,
                                note: "Stream trực tiếp qua AVPlayer có hợp đồng cấp phép."
                            )

                            capabilityRow(
                                provider: .localLibrary,
                                status: "Phát nền (Background)",
                                isSupported: true,
                                note: "Tệp âm thanh cục bộ trên thiết bị."
                            )
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 7. PRIVACY & HISTORY
                    Section(header: Text("Quyền riêng tư & Lưu trữ").foregroundColor(WaveMixColors.textTertiary)) {
                        Button(action: { showClearHistoryAlert = true }) {
                            Text("Xóa lịch sử tìm kiếm & phát nhạc")
                                .foregroundColor(Color.red)
                        }

                        NavigationLink("Chi tiết Privacy Manifest") {
                            privacyManifestView
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)

                    // 8. ABOUT
                    Section(header: Text("Về WaveMix").foregroundColor(WaveMixColors.textTertiary)) {
                        HStack {
                            Text("Tác giả")
                            Spacer()
                            Text("Quốc Tín")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(WaveMixColors.neonCyan)
                        }

                        HStack {
                            Text("Phiên bản")
                            Spacer()
                            Text("1.1.0 (Vietnam Edition)")
                                .foregroundColor(WaveMixColors.textSecondary)
                        }

                        HStack {
                            Text("Khẩu hiệu (Tagline)")
                            Spacer()
                            Text(WaveMixColors.brandTagline)
                                .font(.system(size: 11))
                                .foregroundColor(WaveMixColors.accentPink)
                        }
                    }
                    .listRowBackground(WaveMixColors.surfaceDark)
                }
                .scrollContentBackground(.hidden)
                .padding(.bottom, 80)
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showOnboardingModal) {
                OnboardingView {
                    showOnboardingModal = false
                }
            }
            .alert("Xóa lịch sử", isPresented: $showClearHistoryAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa tất cả", role: .destructive) {
                    storageService.clearSearchHistory()
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa lịch sử tìm kiếm cục bộ không?")
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
            WaveMixColors.midnightBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Privacy Manifest (PrivacyInfo.xcprivacy)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(WaveMixColors.textPrimary)

                    Text("WaveMix cam kết bảo vệ dữ liệu người dùng và tuân thủ tuyệt đối quy định bảo mật Apple Privacy Manifest.")
                        .font(.system(size: 13))
                        .foregroundColor(WaveMixColors.textSecondary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Tên miền theo dõi: Không có. WaveMix không theo dõi người dùng.")
                        Text("• API khai báo lý do bắt buộc: UserDefaults (Lưu cài đặt), FileTimestamp (Quản lý cache cục bộ).")
                        Text("• Tìm kiếm YouTube trực tiếp từ máy khách thông qua YouTube Data API v3 chính thức.")
                        Text("• Không lưu trữ tài khoản hoặc mật khẩu YouTube của người dùng.")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(WaveMixColors.textSecondary)
                }
                .padding(20)
            }
        }
        .navigationTitle("Quyền riêng tư")
    }

    private func checkMusicKitStatus() async {
        let status = MusicAuthorization.currentStatus
        switch status {
        case .authorized:
            musicKitStatusText = "Đã ủy quyền"
            canRequestMusicKit = false
        case .denied:
            musicKitStatusText = "Bị từ chối trong Cài đặt iOS"
            canRequestMusicKit = false
        case .notDetermined:
            musicKitStatusText = "Chưa yêu cầu"
            canRequestMusicKit = true
        case .restricted:
            musicKitStatusText = "Bị hạn chế (Parental Controls)"
            canRequestMusicKit = false
        @unknown default:
            musicKitStatusText = "Trạng thái không xác định"
            canRequestMusicKit = true
        }
    }

    private func updateMusicKitStatus(status: AppleMusicAccessStatus) {
        switch status {
        case .authorized(let canPlay):
            musicKitStatusText = canPlay ? "Đã ủy quyền (Gói nghe nhạc hợp lệ)" : "Đã ủy quyền (Chế độ Preview)"
            canRequestMusicKit = false
        case .denied:
            musicKitStatusText = "Bị từ chối"
            canRequestMusicKit = false
        case .restricted:
            musicKitStatusText = "Bị hạn chế"
            canRequestMusicKit = false
        case .notDetermined:
            musicKitStatusText = "Đang chờ"
            canRequestMusicKit = true
        }
    }
}
