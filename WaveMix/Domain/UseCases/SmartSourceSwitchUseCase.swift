import Foundation

/// Result candidate for smart source switching
public struct LicensedMatchCandidate: Identifiable, Equatable, Sendable {
    public var id: UUID { track.id }
    public let track: MusicTrack
    public let confidenceScore: Double // 0.0 to 1.0
    public let matchReason: String

    public init(track: MusicTrack, confidenceScore: Double, matchReason: String) {
        self.track = track
        self.confidenceScore = confidenceScore
        self.matchReason = matchReason
    }
}

/// Smart source switcher: Finds licensed counterparts for YouTube tracks.
/// Under strict policy, WaveMix never rips audio from YouTube.
/// Instead, it intelligently resolves song and artist metadata to find licensed versions
/// on Apple Music or the Licensed Catalog with explicit user confirmation.
public final class SmartSourceSwitchUseCase: Sendable {
    private let appleMusicSearcher: MusicSearchProvider?
    private let licensedCatalogSearcher: MusicSearchProvider?

    public init(
        appleMusicSearcher: MusicSearchProvider?,
        licensedCatalogSearcher: MusicSearchProvider?
    ) {
        self.appleMusicSearcher = appleMusicSearcher
        self.licensedCatalogSearcher = licensedCatalogSearcher
    }

    /// Cleans YouTube video titles to extract essential song name and artist
    /// E.g. "Adele - Easy On Me (Official Music Video) [4K]" -> Artist: "Adele", Song: "Easy On Me"
    public func cleanMetadata(from youtubeTitle: String, channelTitle: String?) -> (artist: String, title: String) {
        var cleaned = youtubeTitle
        
        // Remove common YouTube fluff in parentheses or brackets
        let fluffPatterns = [
            "\\(Official\\s*(Music\\s*)?Video\\)",
            "\\[Official\\s*(Music\\s*)?Video\\]",
            "\\(Official\\s*Audio\\)",
            "\\[Official\\s*Audio\\]",
            "\\(Lyric\\s*Video\\)",
            "\\[Lyric\\s*Video\\]",
            "\\(Lyrics\\)",
            "\\[Lyrics\\]",
            "\\(Audio\\)",
            "\\[Audio\\]",
            "\\(MV\\)",
            "\\[MV\\]",
            "\\(Visualizer\\)",
            "\\[Visualizer\\]",
            "\\(4K\\)",
            "\\[4K\\]",
            "\\(HD\\)",
            "\\[HD\\]",
            "\\|.*$"
        ]

        for pattern in fluffPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    options: [],
                    range: NSRange(location: 0, length: cleaned.utf16.count),
                    withTemplate: ""
                )
            }
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for common "Artist - Title" separator
        let separators = [" - ", " – ", " — ", " : "]
        for sep in separators {
            if cleaned.contains(sep) {
                let parts = cleaned.components(separatedBy: sep)
                if parts.count >= 2 {
                    let artist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let title = parts[1...].joined(separator: sep).trimmingCharacters(in: .whitespacesAndNewlines)
                    return (artist: artist, title: title)
                }
            }
        }

        // Fallback: Channel name as artist, cleaned string as title
        let fallbackArtist = channelTitle?.replacingOccurrences(of: " - Topic", with: "").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (artist: fallbackArtist, title: cleaned)
    }

    /// Search licensed sources for equivalent tracks and rank them
    public func findLicensedVersions(for track: MusicTrack) async throws -> [LicensedMatchCandidate] {
        guard track.provider == .youtube else {
            return []
        }

        let metadata = cleanMetadata(from: track.title, channelTitle: track.channelTitle ?? track.artist)
        let query = "\(metadata.artist) \(metadata.title)".trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }

        var candidates: [LicensedMatchCandidate] = []

        // 1. Search Apple Music
        if let appleSearch = appleMusicSearcher {
            do {
                let appleFilter = SearchFilter(provider: .appleMusic, category: .songs, limit: 10)
                let result = try await appleSearch.search(query: query, filter: appleFilter, pageToken: nil)
                for item in result.tracks {
                    let score = calculateConfidence(sourceArtist: metadata.artist, sourceTitle: metadata.title, candidate: item)
                    if score > 0.4 {
                        candidates.append(LicensedMatchCandidate(
                            track: item,
                            confidenceScore: score,
                            matchReason: "Apple Music Catalog (Match: \(Int(score * 100))%)"
                        ))
                    }
                }
            } catch {
                // Non-fatal, continue with other providers
            }
        }

        // 2. Search Licensed Catalog
        if let catalogSearch = licensedCatalogSearcher {
            do {
                let catalogFilter = SearchFilter(provider: .licensedCatalog, category: .songs, limit: 10)
                let result = try await catalogSearch.search(query: query, filter: catalogFilter, pageToken: nil)
                for item in result.tracks {
                    let score = calculateConfidence(sourceArtist: metadata.artist, sourceTitle: metadata.title, candidate: item)
                    if score > 0.4 {
                        candidates.append(LicensedMatchCandidate(
                            track: item,
                            confidenceScore: score,
                            matchReason: "Licensed Catalog (Match: \(Int(score * 100))%)"
                        ))
                    }
                }
            } catch {
                // Non-fatal
            }
        }

        // Sort descending by confidence score
        return candidates.sorted(by: { $0.confidenceScore > $1.confidenceScore })
    }

    private func calculateConfidence(sourceArtist: String, sourceTitle: String, candidate: MusicTrack) -> Double {
        let normSourceArtist = sourceArtist.lowercased().filter { $0.isLetter || $0.isNumber }
        let normSourceTitle = sourceTitle.lowercased().filter { $0.isLetter || $0.isNumber }
        let normCandArtist = candidate.artist.lowercased().filter { $0.isLetter || $0.isNumber }
        let normCandTitle = candidate.title.lowercased().filter { $0.isLetter || $0.isNumber }

        var score = 0.0

        if normCandTitle == normSourceTitle {
            score += 0.5
        } else if normCandTitle.contains(normSourceTitle) || normSourceTitle.contains(normCandTitle) {
            score += 0.35
        }

        if normCandArtist == normSourceArtist {
            score += 0.5
        } else if normCandArtist.contains(normSourceArtist) || normSourceArtist.contains(normCandArtist) {
            score += 0.35
        }

        return min(1.0, score)
    }
}
