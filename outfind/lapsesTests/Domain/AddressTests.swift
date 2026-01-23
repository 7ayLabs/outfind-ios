import Testing
import Foundation
@testable import lapses

/// Tests for Address value object
struct AddressTests {

    // MARK: - Initialization Tests

    @Test("Valid address with 0x prefix initializes correctly")
    func validAddressWithPrefixInitializes() {
        let address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
        #expect(address != nil)
        #expect(address?.hex == "0xd8da6bf26964af9d7eed9e03e53415d37aa96045")
    }

    @Test("Valid address without 0x prefix initializes correctly")
    func validAddressWithoutPrefixInitializes() {
        let address = Address(rawValue: "d8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
        #expect(address != nil)
        #expect(address?.hex == "0xd8da6bf26964af9d7eed9e03e53415d37aa96045")
    }

    @Test("Address is normalized to lowercase")
    func addressIsNormalizedToLowercase() {
        let address = Address(rawValue: "0xD8DA6BF26964AF9D7EED9E03E53415D37AA96045")
        #expect(address?.hex == "0xd8da6bf26964af9d7eed9e03e53415d37aa96045")
    }

    @Test("Invalid address with wrong length returns nil")
    func invalidLengthReturnsNil() {
        #expect(Address(rawValue: "0x1234") == nil)
        #expect(Address(rawValue: "0x12345678901234567890123456789012345678901") == nil)
    }

    @Test("Invalid address with non-hex characters returns nil")
    func invalidCharactersReturnsNil() {
        #expect(Address(rawValue: "0xGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG") == nil)
        #expect(Address(rawValue: "0x123456789012345678901234567890123456xyz!") == nil)
    }

    @Test("Empty string returns nil")
    func emptyStringReturnsNil() {
        #expect(Address(rawValue: "") == nil)
    }

    // MARK: - Zero Address Tests

    @Test("Zero address constant is valid")
    func zeroAddressIsValid() {
        #expect(Address.zero.hex == "0x0000000000000000000000000000000000000000")
    }

    // MARK: - Abbreviated Tests

    @Test("abbreviated returns correctly formatted short address")
    func abbreviatedReturnsCorrectFormat() {
        let address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        #expect(address.abbreviated == "0xd8da...6045")
    }

    @Test("description uses abbreviated format")
    func descriptionUsesAbbreviated() {
        let address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        #expect(address.description == address.abbreviated)
    }

    // MARK: - Data Conversion Tests

    @Test("Address converts to 20-byte Data correctly")
    func addressConvertsToData() {
        let address = Address(rawValue: "0x0000000000000000000000000000000000000001")!
        let data = address.data
        #expect(data != nil)
        #expect(data?.count == 20)
        #expect(data?.last == 1)
    }

    @Test("Address initializes from 20-byte Data")
    func addressInitializesFromData() {
        var data = Data(repeating: 0, count: 19)
        data.append(1)
        let address = Address(data: data)
        #expect(address?.hex == "0x0000000000000000000000000000000000000001")
    }

    @Test("Address from invalid Data length returns nil")
    func addressFromInvalidDataLengthReturnsNil() {
        #expect(Address(data: Data([1, 2, 3])) == nil)
        #expect(Address(data: Data(repeating: 0, count: 21)) == nil)
    }

    // MARK: - Equatable Tests

    @Test("Addresses with same value are equal")
    func sameAddressesAreEqual() {
        let address1 = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
        let address2 = Address(rawValue: "0xD8DA6BF26964AF9D7EED9E03E53415D37AA96045")
        #expect(address1 == address2)
    }

    @Test("Different addresses are not equal")
    func differentAddressesAreNotEqual() {
        let address1 = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")
        let address2 = Address(rawValue: "0x0000000000000000000000000000000000000001")
        #expect(address1 != address2)
    }

    // MARK: - Hashable Tests

    @Test("Addresses with same value have same hash")
    func sameAddressesHaveSameHash() {
        let address1 = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        let address2 = Address(rawValue: "0xD8DA6BF26964AF9D7EED9E03E53415D37AA96045")!
        #expect(address1.hashValue == address2.hashValue)
    }

    @Test("Address can be used as dictionary key")
    func addressCanBeUsedAsDictionaryKey() {
        let address = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        var dict: [Address: String] = [:]
        dict[address] = "test"
        #expect(dict[address] == "test")
    }

    // MARK: - Codable Tests

    @Test("Address encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        let original = Address(rawValue: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045")!
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Address.self, from: data)
        #expect(decoded == original)
    }

    @Test("Invalid address in JSON throws decoding error")
    func invalidAddressInJSONThrowsError() throws {
        let invalidJSON = "\"0x1234\""
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(Address.self, from: invalidJSON.data(using: .utf8)!)
        }
    }
}

// MARK: - Data Extension Tests

struct DataExtensionTests {

    @Test("Data initializes from valid hex string")
    func dataInitializesFromValidHexString() {
        let data = Data(hexString: "0x0102030405")
        #expect(data != nil)
        #expect(data == Data([1, 2, 3, 4, 5]))
    }

    @Test("Data initializes from hex string without prefix")
    func dataInitializesFromHexStringWithoutPrefix() {
        let data = Data(hexString: "0102030405")
        #expect(data != nil)
        #expect(data == Data([1, 2, 3, 4, 5]))
    }

    @Test("Data from odd-length hex string returns nil")
    func oddLengthHexStringReturnsNil() {
        #expect(Data(hexString: "123") == nil)
    }

    @Test("Data from invalid hex characters returns nil")
    func invalidHexCharactersReturnsNil() {
        #expect(Data(hexString: "GGGG") == nil)
    }

    @Test("hexString property returns correct format")
    func hexStringPropertyReturnsCorrectFormat() {
        let data = Data([1, 2, 3, 4, 5, 255])
        #expect(data.hexString == "01020304050ff")
    }
}
