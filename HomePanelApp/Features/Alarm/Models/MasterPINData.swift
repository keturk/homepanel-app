import Foundation
import CryptoKit

// MARK: - Master PIN Data Model

public struct MasterPINData: Codable {
    public let pinHash: String  // SHA-256 hash of the master PIN
    public let salt: String     // Random salt used for hashing
    public var lastUsed: Date?  // When the Master PIN was last used
    
    public init(pin: String) throws {
        // Perform all throwing operations FIRST before assigning to self
        let salt = PINHasher.generateSalt()
        let pinHash = try PINHasher.hashPIN(pin, salt: salt)

        // Now assign all properties after validation succeeds
        self.pinHash = pinHash
        self.salt = salt
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
