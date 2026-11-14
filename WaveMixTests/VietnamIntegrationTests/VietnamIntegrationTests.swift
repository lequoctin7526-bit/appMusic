import XCTest
import SwiftUI
@testable import WaveMix

final class VietnamIntegrationTests: XCTestCase {

    func testVietnamRegionalConfigurationDefaults() {
        let config = AppConfig.shared
        XCTAssertEqual(config.defaultRegionCode, "VN")
        XCTAssertEqual(config.defaultLanguage, "vi")
        XCTAssertEqual(config.defaultLocale, "vi_VN")
        XCTAssertEqual(config.defaultTimezone, "Asia/Ho_Chi_Minh")

        // Test date formatting conforming to dd/MM/yyyy
        let testDateComponents = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(identifier: "Asia/Ho_Chi_Minh"),
            year: 2026,
            month: 11,
            day: 14
        )
        guard let testDate = testDateComponents.date else {
            XCTFail("Failed to generate test date")
            return
        }

        let formatted = config.standardDateFormatter.string(from: testDate)
        XCTAssertEqual(formatted, "14/11/2026", "Vietnam date format must be dd/MM/yyyy")
    }

    func testVietnamMusicCategoriesCompleteness() {
        let allCategories = VietnamMusicCategory.allCases
        XCTAssertEqual(allCategories.count, 12, "WaveMix must provide exactly 12 curated Vietnamese music categories")

        for category in allCategories {
            XCTAssertFalse(category.displayName.isEmpty, "Category \(category.rawValue) must have a display name")
            XCTAssertFalse(category.systemIcon.isEmpty, "Category \(category.rawValue) must have a valid SF Symbol name")
            XCTAssertFalse(category.searchQueries.isEmpty, "Category \(category.rawValue) must have at least one search query")
        }

        // Check key Vietnamese genres are present
        let categoryIDs = Set(allCategories.map { $0.id })
        XCTAssertTrue(categoryIDs.contains("vpop"))
        XCTAssertTrue(categoryIDs.contains("rap_viet"))
        XCTAssertTrue(categoryIDs.contains("bolero"))
        XCTAssertTrue(categoryIDs.contains("indie_viet"))
        XCTAssertTrue(categoryIDs.contains("nhac_tre"))
        XCTAssertTrue(categoryIDs.contains("nhac_tru_tinh"))
    }

    func testVietnameseChannelBadgeEntitySupport() {
        let defaultTrack = MusicTrack(
            provider: .youtube,
            title: "Nơi Này Có Anh",
            artist: "Sơn Tùng M-TP",
            providerTrackID: "FN7ALfpGxiI"
        )
        XCTAssertFalse(defaultTrack.isVietnameseChannel, "Default track isVietnameseChannel should be false")

        let vnTrack = MusicTrack(
            provider: .youtube,
            title: "Nấu Ăn Cho Em",
            artist: "Đen Vâu",
            providerTrackID: "example_id",
            isVietnameseChannel: true
        )
        XCTAssertTrue(vnTrack.isVietnameseChannel, "Vietnam channel track must retain isVietnameseChannel == true")
    }

    func testBrandIdentityColorsAndTagline() {
        XCTAssertEqual(WaveMixColors.tagline, "Feel Every Beat. Discover Every Song.")

        // Verify brand color constants can be referenced without issue
        _ = WaveMixColors.midnightBlack
        _ = WaveMixColors.deepPurple
        _ = WaveMixColors.electricBlue
        _ = WaveMixColors.neonCyan
        _ = WaveMixColors.accentPink
        _ = WaveMixColors.primaryGradient
    }

    func testVietnameseSearchQueriesNormalization() {
        let sampleVietnameseQueries = [
            "Sơn Tùng M-TP",
            "Đen Vâu Đi Về Nhà",
            "Vũ. Bước Qua Nhau",
            "Hà Anh Tuấn Chân Trời Rực Rỡ"
        ]

        for query in sampleVietnameseQueries {
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            XCTAssertNotNil(encoded, "Vietnamese characters with diacritics must encode properly for URL parameters")
            XCTAssertFalse(encoded!.isEmpty)
        }
    }
}
