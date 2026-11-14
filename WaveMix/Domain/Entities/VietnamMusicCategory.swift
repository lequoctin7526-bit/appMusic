import Foundation

/// 12 Curated Vietnamese Music Categories
public enum VietnamMusicCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case vpop = "vpop"
    case nhacTre = "nhac_tre"
    case rapViet = "rap_viet"
    case indieViet = "indie_viet"
    case bolero = "bolero"
    case nhacTruTinh = "nhac_tru_tinh"
    case remixViet = "remix_viet"
    case nhacTikTok = "nhac_tiktok"
    case acousticViet = "acoustic_viet"
    case nhacHoaLoiViet = "nhac_hoa_loi_viet"
    case nhacBatHu = "nhac_bat_hu"
    case nhacMoi = "nhac_moi"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .vpop:
            return "V-Pop"
        case .nhacTre:
            return "Nhạc trẻ Việt Nam"
        case .rapViet:
            return "Rap Việt"
        case .indieViet:
            return "Indie Việt"
        case .bolero:
            return "Bolero"
        case .nhacTruTinh:
            return "Nhạc trữ tình"
        case .remixViet:
            return "Remix Việt Nam"
        case .nhacTikTok:
            return "Nhạc TikTok Việt Nam"
        case .acousticViet:
            return "Nhạc Acoustic Việt"
        case .nhacHoaLoiViet:
            return "Nhạc Hoa lời Việt"
        case .nhacBatHu:
            return "Nhạc Việt bất hủ"
        case .nhacMoi:
            return "Nhạc mới phát hành"
        }
    }

    public var systemIcon: String {
        switch self {
        case .vpop:
            return "flame.fill"
        case .nhacTre:
            return "sparkles"
        case .rapViet:
            return "mic.fill"
        case .indieViet:
            return "guitars.fill"
        case .bolero:
            return "music.quarternote.3"
        case .nhacTruTinh:
            return "heart.fill"
        case .remixViet:
            return "waveform.badge.plus"
        case .nhacTikTok:
            return "play.circle.fill"
        case .acousticViet:
            return "speaker.wave.1.fill"
        case .nhacHoaLoiViet:
            return "globe.asia.australia.fill"
        case .nhacBatHu:
            return "crown.fill"
        case .nhacMoi:
            return "sparkle"
        }
    }

    /// Primary search queries for fetching real YouTube music results
    public var searchQueries: [String] {
        switch self {
        case .vpop:
            return ["V-Pop mới nhất", "V-Pop trending"]
        case .nhacTre:
            return ["Nhạc trẻ Việt Nam 2026", "Nhạc trẻ chọn lọc"]
        case .rapViet:
            return ["Rap Việt mới nhất", "Rap Việt trending"]
        case .indieViet:
            return ["Indie Việt Nam", "Indie Chill Việt"]
        case .bolero:
            return ["Bolero trữ tình", "Bolero chọn lọc"]
        case .nhacTruTinh:
            return ["Nhạc trữ tình quê hương", "Nhạc trữ tình sâu lắng"]
        case .remixViet:
            return ["Remix Việt Nam", "Vinahouse mới nhất"]
        case .nhacTikTok:
            return ["Nhạc TikTok Việt Nam hot", "TikTok trending VN"]
        case .acousticViet:
            return ["Nhạc Acoustic Việt", "Acoustic cover hay nhất"]
        case .nhacHoaLoiViet:
            return ["Nhạc Hoa lời Việt bất hủ", "Nhạc Hoa lời Việt mới"]
        case .nhacBatHu:
            return ["Nhạc Việt bất hủ", "Tình khúc vượt thời gian"]
        case .nhacMoi:
            return ["Nhạc mới phát hành", "Top bài hát Việt Nam"]
        }
    }
}
