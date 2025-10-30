import XCTest
@testable import HomePanelApp

// MARK: - PIN Hasher Tests

class PINHasherTests: XCTestCase {

    // MARK: - Salt Generation Tests

    func testGenerateSalt() {
        // When generating salt
        let salt = PINHasher.generateSalt()

        // Then should produce non-empty salt
        XCTAssertFalse(salt.isEmpty, "Salt should not be empty")
    }

    func testGeneratedSaltsAreUnique() {
        // When generating multiple salts
        let salt1 = PINHasher.generateSalt()
        let salt2 = PINHasher.generateSalt()
        let salt3 = PINHasher.generateSalt()

        // Then all should be unique
        XCTAssertNotEqual(salt1, salt2, "Salts should be unique")
        XCTAssertNotEqual(salt2, salt3, "Salts should be unique")
        XCTAssertNotEqual(salt1, salt3, "Salts should be unique")
    }

    func testSaltIsBase64Encoded() {
        // When generating salt
        let salt = PINHasher.generateSalt()

        // Then should be valid base64
        XCTAssertNotNil(Data(base64Encoded: salt), "Salt should be valid base64")
    }

    // MARK: - Hashing Tests

    func testHashPINWithSalt() throws {
        // Given a PIN and salt
        let pin = "1234"
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should produce a hash
        XCTAssertFalse(hash.isEmpty, "Hash should not be empty")
        XCTAssertNotEqual(hash, pin, "Hash should not equal plain PIN")
    }

    func testHashingIsDeterministic() throws {
        // Given a PIN and salt
        let pin = "1234"
        let salt = PINHasher.generateSalt()

        // When hashing multiple times with same salt
        let hash1 = try PINHasher.hashPIN(pin, salt: salt)
        let hash2 = try PINHasher.hashPIN(pin, salt: salt)
        let hash3 = try PINHasher.hashPIN(pin, salt: salt)

        // Then should produce same hash
        XCTAssertEqual(hash1, hash2, "Same PIN and salt should produce same hash")
        XCTAssertEqual(hash2, hash3, "Same PIN and salt should produce same hash")
    }

    func testDifferentPINsProduceDifferentHashes() throws {
        // Given different PINs with same salt
        let salt = PINHasher.generateSalt()
        let pin1 = "1234"
        let pin2 = "5678"
        let pin3 = "0000"

        // When hashing
        let hash1 = try PINHasher.hashPIN(pin1, salt: salt)
        let hash2 = try PINHasher.hashPIN(pin2, salt: salt)
        let hash3 = try PINHasher.hashPIN(pin3, salt: salt)

        // Then should produce different hashes
        XCTAssertNotEqual(hash1, hash2, "Different PINs should produce different hashes")
        XCTAssertNotEqual(hash2, hash3, "Different PINs should produce different hashes")
        XCTAssertNotEqual(hash1, hash3, "Different PINs should produce different hashes")
    }

    func testDifferentSaltsProduceDifferentHashes() throws {
        // Given same PIN with different salts
        let pin = "1234"
        let salt1 = PINHasher.generateSalt()
        let salt2 = PINHasher.generateSalt()
        let salt3 = PINHasher.generateSalt()

        // When hashing
        let hash1 = try PINHasher.hashPIN(pin, salt: salt1)
        let hash2 = try PINHasher.hashPIN(pin, salt: salt2)
        let hash3 = try PINHasher.hashPIN(pin, salt: salt3)

        // Then should produce different hashes
        XCTAssertNotEqual(hash1, hash2, "Different salts should produce different hashes")
        XCTAssertNotEqual(hash2, hash3, "Different salts should produce different hashes")
        XCTAssertNotEqual(hash1, hash3, "Different salts should produce different hashes")
    }

    func testHashIsBase64Encoded() throws {
        // Given a PIN and salt
        let pin = "1234"
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then hash should be valid base64
        XCTAssertNotNil(Data(base64Encoded: hash), "Hash should be valid base64")
    }

    // MARK: - Security Tests

    func testHashIsNotReversible() throws {
        // Given a PIN and salt
        let pin = "1234"
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then hash should not contain PIN in plain text
        XCTAssertFalse(hash.contains(pin), "Hash should not contain plain PIN")
    }

    func testHashLengthIsConsistent() throws {
        // Given various PINs
        let pins = ["1", "12", "123", "1234", "12345", "123456"]
        let salt = PINHasher.generateSalt()

        // When hashing
        let hashes = try pins.map { try PINHasher.hashPIN($0, salt: salt) }

        // Then all hashes should have same length (SHA-256 base64)
        let firstLength = hashes[0].count
        for hash in hashes {
            XCTAssertEqual(hash.count, firstLength, "All hashes should have consistent length")
        }
    }

    func testCanVerifyCorrectPIN() throws {
        // Given a PIN, salt, and hash
        let pin = "1234"
        let salt = PINHasher.generateSalt()
        let originalHash = try PINHasher.hashPIN(pin, salt: salt)

        // When verifying correct PIN
        let verifyHash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should match
        XCTAssertEqual(verifyHash, originalHash, "Correct PIN should produce matching hash")
    }

    func testCannotVerifyIncorrectPIN() throws {
        // Given a PIN, salt, and hash
        let correctPIN = "1234"
        let incorrectPIN = "9999"
        let salt = PINHasher.generateSalt()
        let originalHash = try PINHasher.hashPIN(correctPIN, salt: salt)

        // When verifying incorrect PIN
        let verifyHash = try PINHasher.hashPIN(incorrectPIN, salt: salt)

        // Then should not match
        XCTAssertNotEqual(verifyHash, originalHash, "Incorrect PIN should not match")
    }

    // MARK: - Edge Cases

    func testHashEmptyPIN() throws {
        // Given empty PIN
        let pin = ""
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should still produce a hash
        XCTAssertFalse(hash.isEmpty, "Should produce hash even for empty PIN")
    }

    func testHashLongPIN() throws {
        // Given very long PIN
        let pin = String(repeating: "1234567890", count: 100)
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should produce a hash
        XCTAssertFalse(hash.isEmpty, "Should handle long PINs")
    }

    func testHashSpecialCharactersPIN() throws {
        // Given PIN with special characters
        let pin = "!@#$%^&*()"
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should produce a hash
        XCTAssertFalse(hash.isEmpty, "Should handle special characters")
    }

    func testHashUnicodePIN() throws {
        // Given PIN with unicode characters
        let pin = "🔒🔑1234"
        let salt = PINHasher.generateSalt()

        // When hashing
        let hash = try PINHasher.hashPIN(pin, salt: salt)

        // Then should produce a hash
        XCTAssertFalse(hash.isEmpty, "Should handle unicode characters")
    }

    // MARK: - Collision Tests

    func testNoCollisionsInCommonRange() throws {
        // Given common 4-digit PINs (0000-9999)
        let salt = PINHasher.generateSalt()
        var hashes = Set<String>()

        // When hashing first 1000 PINs
        for i in 0..<1000 {
            let pin = String(format: "%04d", i)
            let hash = try PINHasher.hashPIN(pin, salt: salt)
            hashes.insert(hash)
        }

        // Then all should be unique
        XCTAssertEqual(hashes.count, 1000, "Should have no collisions in 1000 PINs")
    }

    // MARK: - Salt Validation Tests

    func testHashWithInvalidSaltThrows() {
        // Given invalid salt (not base64)
        let pin = "1234"
        let invalidSalt = "not-valid-base64!!!"

        // When hashing with invalid salt
        // Then should throw
        XCTAssertThrowsError(try PINHasher.hashPIN(pin, salt: invalidSalt)) { error in
            XCTAssertTrue(error is SecurityError, "Should throw SecurityError")
        }
    }

    func testHashWithEmptySalt() throws {
        // Given empty salt (empty string is valid base64)
        let pin = "1234"
        let emptySalt = ""

        // When hashing with empty salt
        let hash = try PINHasher.hashPIN(pin, salt: emptySalt)

        // Then should produce a hash (empty string is valid base64, results in empty salt data)
        XCTAssertFalse(hash.isEmpty, "Should produce hash even with empty salt")
    }

    // MARK: - Performance Tests

    func testHashingPerformance() throws {
        // Given a PIN and salt
        let pin = "1234"
        let salt = PINHasher.generateSalt()

        // When measuring hashing performance
        measure {
            for _ in 0..<100 {
                _ = try? PINHasher.hashPIN(pin, salt: salt)
            }
        }
    }

    func testSaltGenerationPerformance() {
        // When measuring salt generation performance
        measure {
            for _ in 0..<100 {
                _ = PINHasher.generateSalt()
            }
        }
    }
}
