import Foundation

/// Coordinates multi-source search operations while maintaining strict provider separation.
public final class SearchMusicUseCase: Sendable {
    private let providers: [MusicProvider: MusicSearchProvider]

    public init(providers: [MusicProvider: MusicSearchProvider]) {
        self.providers = providers
    }

    public func search(query: String, filter: SearchFilter) async throws -> [MusicProvider: SearchResultPage] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [:] }

        // If a specific provider is requested:
        if let specific = filter.provider {
            guard let provider = providers[specific] else {
                return [:]
            }
            let page = try await provider.search(query: trimmed, filter: filter, pageToken: nil)
            return [specific: page]
        }

        // Otherwise execute multi-source search concurrently
        return try await withThrowingTaskGroup(of: (MusicProvider, SearchResultPage)?.self) { group in
            for (key, provider) in providers {
                group.addTask {
                    do {
                        let page = try await provider.search(query: trimmed, filter: filter, pageToken: nil)
                        return (key, page)
                    } catch {
                        // Failures from one provider shouldn't bring down the others
                        return nil
                    }
                }
            }

            var results: [MusicProvider: SearchResultPage] = [:]
            for try await result in group {
                if let (key, page) = result {
                    results[key] = page
                }
            }
            return results
        }
    }
}
