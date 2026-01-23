import Foundation

/// Network-related constants that don't vary by environment
/// Environment-specific URLs are in Configuration
enum NetworkConstants {
    // MARK: - Timeouts

    /// Default HTTP request timeout in seconds
    static let defaultHTTPTimeout: TimeInterval = 30

    /// WebSocket connection timeout in seconds
    static let wsConnectionTimeout: TimeInterval = 15

    /// WebSocket ping interval in seconds
    static let wsPingInterval: TimeInterval = 30

    /// WebSocket reconnection delay in seconds
    static let wsReconnectionDelay: TimeInterval = 5

    // MARK: - Retry Configuration

    /// Maximum number of retry attempts for network requests
    static let maxRetryAttempts = 3

    /// Base delay for exponential backoff in seconds
    static let retryBaseDelay: TimeInterval = 1.0

    /// Maximum delay for exponential backoff in seconds
    static let retryMaxDelay: TimeInterval = 30.0

    /// Jitter factor for retry delays (0.0 to 1.0)
    static let retryJitterFactor: Double = 0.1

    // MARK: - Request Limits

    /// Maximum concurrent network requests
    static let maxConcurrentRequests = 10

    /// Maximum request body size in bytes (10 MB)
    static let maxRequestBodySize = 10_485_760

    /// Maximum response size in bytes (50 MB)
    static let maxResponseSize = 52_428_800

    // MARK: - Cache Configuration

    /// Memory cache size in bytes (20 MB)
    static let memoryCacheSize = 20_971_520

    /// Disk cache size in bytes (100 MB)
    static let diskCacheSize = 104_857_600

    /// Default cache expiration in seconds (5 minutes)
    static let defaultCacheExpiration: TimeInterval = 300
}

// MARK: - HTTP Headers

extension NetworkConstants {
    enum HTTPHeader {
        static let contentType = "Content-Type"
        static let accept = "Accept"
        static let authorization = "Authorization"
        static let userAgent = "User-Agent"
        static let epochId = "X-Epoch-Id"
        static let signature = "X-Signature"
        static let timestamp = "X-Timestamp"
        static let nonce = "X-Nonce"
    }

    enum ContentType {
        static let json = "application/json"
        static let formURLEncoded = "application/x-www-form-urlencoded"
        static let multipartFormData = "multipart/form-data"
        static let octetStream = "application/octet-stream"
    }
}

// MARK: - Retry Strategy

extension NetworkConstants {
    /// Calculate delay for retry attempt with exponential backoff and jitter
    /// - Parameter attempt: Current attempt number (0-indexed)
    /// - Returns: Delay in seconds before next retry
    static func retryDelay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = retryBaseDelay * pow(2.0, Double(attempt))
        let clampedDelay = min(exponentialDelay, retryMaxDelay)
        let jitter = clampedDelay * retryJitterFactor * Double.random(in: -1...1)
        return clampedDelay + jitter
    }
}
