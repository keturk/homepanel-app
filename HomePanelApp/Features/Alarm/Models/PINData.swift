import Foundation
import CryptoKit

// MARK: - PIN Data Model

public struct PINData: Codable, Identifiable {
    public let id: UUID
    public let pinHash: String  // SHA-256 hash of the PIN
    public let salt: String     // Random salt used for hashing
    public let name: String
    public let createdAt: Date
    public var lastUsed: Date?
    
    public init(pin: String, name: String = "") throws {
        // Perform all throwing operations FIRST before assigning to self
        let salt = PINHasher.generateSalt()
        let pinHash = try PINHasher.hashPIN(pin, salt: salt)

        // Now assign all properties after validation succeeds
        self.id = UUID()
        self.pinHash = pinHash
        self.salt = salt
        self.name = name
        self.createdAt = Date()
        self.lastUsed = nil
    }
    
    // Verify a PIN against this stored data
    public func verifyPIN(_ pin: String) -> Bool {
        do {
            return try PINHasher.hashPIN(pin, salt: self.salt) == self.pinHash
        } catch {
            return false
        }
    }
    
}
