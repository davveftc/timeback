import Foundation
import Security

/// Thread-safe Keychain access for sensitive data (emergency tokens, OTP secrets, used codes).
/// All items use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly for security.
enum KeychainService {
    private static let serviceName = "com.focusbrick.keychain"

    // MARK: - Data

    static func set(_ data: Data, forKey key: String) throws {
        // Delete any existing item first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToStore(status)
        }
    }

    static func get(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Int Convenience

    static func setInt(_ value: Int, forKey key: String) throws {
        let data = withUnsafeBytes(of: value) { Data($0) }
        try set(data, forKey: key)
    }

    static func getInt(forKey key: String) -> Int? {
        guard let data = get(forKey: key), data.count == MemoryLayout<Int>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Int.self) }
    }

    // MARK: - String Set Convenience (for used OTP codes)

    static func setStringSet(_ set: Set<String>, forKey key: String) throws {
        let data = try JSONEncoder().encode(Array(set))
        try Self.set(data, forKey: key)
    }

    static func getStringSet(forKey key: String) -> Set<String> {
        guard let data = get(forKey: key),
              let array = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return Set(array)
    }

    // MARK: - Emergency Unbrick Keys

    static func emergencyKey(for deviceUID: String) -> String {
        "focusbrick.emergency.\(deviceUID)"
    }

    static func getEmergencyCount(for deviceUID: String) -> Int? {
        getInt(forKey: emergencyKey(for: deviceUID))
    }

    static func setEmergencyCount(_ count: Int, for deviceUID: String) throws {
        try setInt(count, forKey: emergencyKey(for: deviceUID))
    }
}

enum KeychainError: LocalizedError {
    case unableToStore(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToStore(let status):
            return "Keychain store failed with status: \(status)"
        }
    }
}
