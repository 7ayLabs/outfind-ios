import Foundation

/// Ethereum address with validation and formatting
/// Represents a 20-byte Ethereum address in hex format
struct Address: Hashable, Equatable, Codable, RawRepresentable, CustomStringConvertible {
    let rawValue: String

    /// The lowercase hex string with 0x prefix
    var hex: String { rawValue }

    /// Abbreviated format for display (0x1234...5678)
    var abbreviated: String {
        guard rawValue.count >= 10 else { return rawValue }
        return "\(rawValue.prefix(6))...\(rawValue.suffix(4))"
    }

    var description: String { abbreviated }

    /// Initialize with validation
    /// - Parameter rawValue: Ethereum address string (with or without 0x prefix)
    /// - Returns: nil if the address is invalid
    init?(rawValue: String) {
        let cleaned = rawValue.lowercased()
        let normalized = cleaned.hasPrefix("0x") ? cleaned : "0x\(cleaned)"

        // Validate: must be 42 characters (0x + 40 hex chars)
        guard normalized.count == 42 else { return nil }

        // Validate: all characters after 0x must be hex digits
        let hexPart = normalized.dropFirst(2)
        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return nil }

        self.rawValue = normalized
    }

    /// Initialize without validation (internal use only)
    private init(unchecked value: String) {
        self.rawValue = value.lowercased()
    }

    /// Zero address constant
    static let zero = Address(unchecked: "0x0000000000000000000000000000000000000000")

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        guard let address = Address(rawValue: value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid Ethereum address: \(value)"
            )
        }
        self = address
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Data Conversion

extension Address {
    /// Convert address to 20-byte Data
    var data: Data? {
        let hexString = String(rawValue.dropFirst(2))
        return Data(hexString: hexString)
    }

    /// Initialize from 20-byte Data
    init?(data: Data) {
        guard data.count == 20 else { return nil }
        let hex = "0x" + data.map { String(format: "%02x", $0) }.joined()
        self.init(rawValue: hex)
    }
}

// MARK: - Data Extension

extension Data {
    /// Initialize Data from hex string
    init?(hexString: String) {
        let hex = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
        guard hex.count % 2 == 0 else { return nil }

        var data = Data()
        var index = hex.startIndex

        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }

        self = data
    }

    /// Convert Data to hex string
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
