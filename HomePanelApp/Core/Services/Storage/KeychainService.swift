import Foundation
import Security

// MARK: - Keychain Service Protocol

/// Protocol defining the interface for secure keychain operations.
/// This protocol provides methods for storing, retrieving, and managing sensitive data
/// such as passwords and credentials in the iOS Keychain.
protocol KeychainServiceProtocol {
    /// Stores a string value in the keychain with the specified key.
    /// - Parameters:
    ///   - key: The unique identifier for the stored value
    ///   - value: The string value to store securely
    ///   - syncable: Whether to sync this value via iCloud Keychain (default: false)
    /// - Throws: SecurityError if the operation fails
    func store(key: String, value: String, syncable: Bool) throws

    /// Retrieves a string value from the keychain using the specified key.
    /// - Parameter key: The unique identifier for the stored value
    /// - Returns: The stored string value
    /// - Throws: SecurityError if the value is not found or cannot be retrieved
    func retrieve(key: String) throws -> String

    /// Stores raw data in the keychain with the specified key.
    /// - Parameters:
    ///   - key: The unique identifier for the stored data
    ///   - value: The data to store securely
    ///   - syncable: Whether to sync this value via iCloud Keychain (default: false)
    /// - Throws: SecurityError if the operation fails
    func storeData(key: String, value: Data, syncable: Bool) throws

    /// Retrieves raw data from the keychain using the specified key.
    /// - Parameter key: The unique identifier for the stored data
    /// - Returns: The stored data
    /// - Throws: SecurityError if the data is not found or cannot be retrieved
    func retrieveData(key: String) throws -> Data

    /// Deletes a value from the keychain using the specified key.
    /// - Parameter key: The unique identifier for the value to delete
    /// - Throws: SecurityError if the operation fails
    func delete(key: String) throws

    /// Deletes all values from the keychain.
    /// - Throws: SecurityError if the operation fails
    func deleteAll() throws

    // MARK: - Camera Password Methods

    /// Saves a camera password securely in the keychain.
    /// - Parameters:
    ///   - cameraId: The unique identifier for the camera
    ///   - password: The password to store securely
    /// - Throws: SecurityError if the operation fails
    func saveCameraPassword(for cameraId: String, password: String) throws

    /// Retrieves a camera password from the keychain.
    /// - Parameter cameraId: The unique identifier for the camera
    /// - Returns: The stored password, or nil if not found
    func getCameraPassword(for cameraId: String) -> String?

    /// Deletes a camera password from the keychain.
    /// - Parameter cameraId: The unique identifier for the camera
    /// - Throws: SecurityError if the operation fails
    func deleteCameraPassword(for cameraId: String) throws
}

// MARK: - Keychain Service

/// Concrete implementation of KeychainServiceProtocol for secure data storage.
/// This class provides thread-safe access to the iOS Keychain for storing and retrieving
/// sensitive information such as passwords and credentials.
class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    /// Shared singleton instance of the KeychainService.
    /// Use this instance for all keychain operations throughout the app.
    static let shared = KeychainService()
    
    /// Private initializer to enforce singleton pattern.
    private init() {}
    
    func store(key: String, value: String, syncable: Bool = false) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecurityError.encodingError
        }
        try storeData(key: key, value: data, syncable: syncable)
    }

    func retrieve(key: String) throws -> String {
        let data = try retrieveData(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecurityError.decodingError
        }
        return string
    }

    func storeData(key: String, value: Data, syncable: Bool = false) throws {
        // First, delete any existing item (both syncable and non-syncable)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Delete both synced and local items
        ]
        SecItemDelete(deleteQuery as CFDictionary)  // Ignore delete errors

        // Now add the new item
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]

        // Add iCloud sync attribute if requested
        if syncable {
            addQuery[kSecAttrSynchronizable as String] = true
        }

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw SecurityError.duplicateItem
        default:
            throw SecurityError.unexpectedKeychainError(status)
        }
    }


    func retrieveData(key: String) throws -> Data {
        // Try to retrieve with syncable attribute first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Search both synced and local items
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw SecurityError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw SecurityError.itemNotFound
        default:
            throw SecurityError.unexpectedKeychainError(status)
        }
    }
    
    func delete(key: String) throws {
        // Try to delete with syncable attribute first (for iCloud synced items)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Delete both synced and local items
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw SecurityError.unexpectedKeychainError(status)
        }
    }
    
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny  // Delete both synced and local items
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw SecurityError.unexpectedKeychainError(status)
        }
    }
    
    // MARK: - Camera Password Methods

    func saveCameraPassword(for cameraId: String, password: String) throws {
        let key = "camera_password_\(cameraId)"
        try store(key: key, value: password, syncable: true)  // Sync camera passwords
    }

    func getCameraPassword(for cameraId: String) -> String? {
        let key = "camera_password_\(cameraId)"
        do {
            return try retrieve(key: key)
        } catch {
            return nil
        }
    }

    func deleteCameraPassword(for cameraId: String) throws {
        let key = "camera_password_\(cameraId)"
        try delete(key: key)
    }
}
