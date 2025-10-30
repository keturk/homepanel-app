import Foundation
import CryptoKit

// MARK: - PIN Hashing Error

// PIN hashing errors are now handled by SecurityError in AppErrors.swift

// MARK: - PIN Hashing Utility

/// A utility class for consistent PIN hashing across the application.
/// Provides static methods for salt generation and PIN hashing using SHA-256.
struct PINHasher {
    
    /// Generates a random salt for PIN hashing
    /// - Returns: A base64-encoded random salt string
    static func generateSalt() -> String {
        let saltData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }
    
    /// Hashes a PIN with the given salt using SHA-256
    /// - Parameters:
    ///   - pin: The PIN string to hash
    ///   - salt: The base64-encoded salt string
    /// - Returns: A base64-encoded hash string
    /// - Throws: SecurityError.pinEncodingFailed if PIN or salt encoding fails
    static func hashPIN(_ pin: String, salt: String) throws -> String {
        guard let saltData = Data(base64Encoded: salt),
              let pinData = pin.data(using: .utf8) else {
            throw SecurityError.pinEncodingFailed
        }
        
        // Combine PIN and salt
        var hasher = SHA256()
        hasher.update(data: pinData)
        hasher.update(data: saltData)
        let hash = hasher.finalize()
        
        return Data(hash).base64EncodedString()
    }
}
