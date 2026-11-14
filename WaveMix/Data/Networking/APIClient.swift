import Foundation

/// Errors encountered during network operations
public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidURL
    case networkUnavailable
    case quotaExceeded(message: String)
    case unauthorized
    case forbidden(message: String)
    case notFound
    case serverError(statusCode: Int)
    case decodingError(message: String)
    case unknown(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL request."
        case .networkUnavailable:
            return "No network connection. Please check your internet settings."
        case .quotaExceeded(let message):
            return "API quota limit reached: \(message)"
        case .unauthorized:
            return "Access unauthorized. Check credentials or subscription."
        case .forbidden(let message):
            return "Access forbidden: \(message)"
        case .notFound:
            return "Requested resource not found."
        case .serverError(let code):
            return "Server responded with error code \(code)."
        case .decodingError(let message):
            return "Failed to parse server response: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

/// Generic, thread-safe asynchronous API client
public final class APIClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                throw NetworkError.networkUnavailable
            }
            throw NetworkError.unknown(message: urlError.localizedDescription)
        } catch {
            throw NetworkError.unknown(message: error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(message: "Invalid response from server.")
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(message: error.localizedDescription)
            }
        case 401:
            throw NetworkError.unauthorized
        case 403:
            // Check if YouTube quota error was returned
            if let str = String(data: data, encoding: .utf8), str.contains("quotaExceeded") {
                throw NetworkError.quotaExceeded(message: "YouTube Data API quota exceeded for today.")
            }
            throw NetworkError.forbidden(message: "Access forbidden (403).")
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.quotaExceeded(message: "Too many requests. Rate limit applied.")
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }
}
