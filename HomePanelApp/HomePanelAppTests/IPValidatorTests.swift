import XCTest
@testable import HomePanelApp

// MARK: - IP Validator Tests

/// Unit tests for IPValidator utility
class IPValidatorTests: XCTestCase {
    
    // MARK: - IPv4 Validation Tests
    
    func testValidIPv4Addresses() {
        // Test valid IP addresses
        let validIPs = [
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "127.0.0.1",
            "0.0.0.0",
            "255.255.255.255",
            "1.1.1.1",
            "8.8.8.8",
            "192.168.0.1",
            "10.10.10.10"
        ]
        
        for ip in validIPs {
            XCTAssertTrue(IPValidator.isValidIPv4(ip), "IP '\(ip)' should be valid")
        }
    }
    
    func testInvalidIPv4Addresses() {
        // Test invalid IP addresses
        let invalidIPs = [
            "",                    // Empty string
            "192.168.1",          // Too few components
            "192.168.1.1.1",      // Too many components
            "192.168.1.",         // Trailing dot
            ".192.168.1.1",       // Leading dot
            "192..168.1.1",       // Double dots
            "192.168.1.1.",       // Trailing dot
            "256.1.1.1",          // Component > 255
            "192.256.1.1",        // Component > 255
            "192.168.256.1",      // Component > 255
            "192.168.1.256",      // Component > 255
            "-1.1.1.1",           // Negative component
            "192.168.1.-1",       // Negative component
            "192.168.1.abc",      // Non-numeric component
            "192.168.1.1a",       // Mixed alphanumeric
            "192.168.01.1",       // Leading zero
            "192.168.001.1",      // Leading zeros
            "192.168.1.01",       // Leading zero
            "192.168.1.1 ",       // Trailing space
            " 192.168.1.1",       // Leading space
            "192.168.1.1\n",      // Newline
            "192.168.1.1\t",      // Tab
            "192.168.1.1 ",       // Space
            "192.168.1.1\r",      // Carriage return
            "192.168.1.1\0",      // Null character
            "192.168.1.1\0\0",    // Multiple null characters
        ]
        
        for ip in invalidIPs {
            XCTAssertFalse(IPValidator.isValidIPv4(ip), "IP '\(ip)' should be invalid")
        }
    }
    
    func testEdgeCaseIPv4Addresses() {
        // Test edge cases
        XCTAssertTrue(IPValidator.isValidIPv4("0.0.0.0"), "0.0.0.0 should be valid")
        XCTAssertTrue(IPValidator.isValidIPv4("255.255.255.255"), "255.255.255.255 should be valid")
        XCTAssertTrue(IPValidator.isValidIPv4("1.1.1.1"), "1.1.1.1 should be valid")
        XCTAssertTrue(IPValidator.isValidIPv4("10.0.0.1"), "10.0.0.1 should be valid")
        
        // Test boundary values
        XCTAssertTrue(IPValidator.isValidIPv4("0.0.0.0"), "0.0.0.0 should be valid")
        XCTAssertTrue(IPValidator.isValidIPv4("255.255.255.255"), "255.255.255.255 should be valid")
        XCTAssertFalse(IPValidator.isValidIPv4("256.0.0.0"), "256.0.0.0 should be invalid")
        XCTAssertFalse(IPValidator.isValidIPv4("0.256.0.0"), "0.256.0.0 should be invalid")
        XCTAssertFalse(IPValidator.isValidIPv4("0.0.256.0"), "0.0.256.0 should be invalid")
        XCTAssertFalse(IPValidator.isValidIPv4("0.0.0.256"), "0.0.0.256 should be invalid")
    }
    
    func testLeadingZeros() {
        // Test leading zeros (should be invalid)
        let invalidWithLeadingZeros = [
            "01.1.1.1",
            "1.01.1.1",
            "1.1.01.1",
            "1.1.1.01",
            "001.1.1.1",
            "1.001.1.1",
            "1.1.001.1",
            "1.1.1.001",
            "010.0.0.1",
            "192.168.010.1"
        ]
        
        for ip in invalidWithLeadingZeros {
            XCTAssertFalse(IPValidator.isValidIPv4(ip), "IP '\(ip)' with leading zeros should be invalid")
        }
    }
    
    // MARK: - Functional Implementation Tests
    
    func testFunctionalImplementation() {
        // Test that both implementations return the same results
        let testIPs = [
            "192.168.1.1",
            "10.0.0.1",
            "127.0.0.1",
            "256.1.1.1",
            "192.168.01.1",
            "192.168.1",
            "192.168.1.1.1",
            "",
            "192.168.1.abc"
        ]
        
        for ip in testIPs {
            let imperativeResult = IPValidator.isValidIPv4(ip)
            let functionalResult = IPValidator.isValidIPv4Functional(ip)
            XCTAssertEqual(imperativeResult, functionalResult, 
                          "Both implementations should return the same result for '\(ip)'")
        }
    }
    
    // MARK: - Port Validation Tests
    
    func testValidPorts() {
        // Test valid port numbers
        let validPorts = [
            "1",
            "80",
            "443",
            "8080",
            "3000",
            "65535",
            "22",
            "21",
            "25",
            "53",
            "110",
            "143",
            "993",
            "995"
        ]
        
        for port in validPorts {
            XCTAssertTrue(IPValidator.isValidPort(port), "Port '\(port)' should be valid")
        }
    }
    
    func testInvalidPorts() {
        // Test invalid port numbers
        let invalidPorts = [
            "",           // Empty string
            "0",          // Zero
            "65536",      // Too large
            "70000",      // Too large
            "-1",         // Negative
            "abc",        // Non-numeric
            "80a",        // Mixed alphanumeric
            " 80",        // Leading space
            "80 ",        // Trailing space
            "80\n",       // Newline
            "80\t",       // Tab
            "80\r",       // Carriage return
            "80\0",       // Null character
            "1.5",        // Decimal
            "1,5",        // Comma
            "1 5",        // Space
        ]
        
        for port in invalidPorts {
            XCTAssertFalse(IPValidator.isValidPort(port), "Port '\(port)' should be invalid")
        }
    }
    
    func testPortBoundaries() {
        // Test port boundaries
        XCTAssertFalse(IPValidator.isValidPort("0"), "Port 0 should be invalid")
        XCTAssertTrue(IPValidator.isValidPort("1"), "Port 1 should be valid")
        XCTAssertTrue(IPValidator.isValidPort("65535"), "Port 65535 should be valid")
        XCTAssertFalse(IPValidator.isValidPort("65536"), "Port 65536 should be invalid")
    }
    
    // MARK: - Combined IP and Port Validation Tests
    
    func testValidIPAndPortCombinations() {
        // Test valid IP and port combinations
        let validCombinations = [
            ("192.168.1.1", "8080"),
            ("10.0.0.1", "80"),
            ("127.0.0.1", "3000"),
            ("172.16.0.1", "443"),
            ("8.8.8.8", "53"),
            ("1.1.1.1", "1"),
            ("255.255.255.255", "65535")
        ]
        
        for (ip, port) in validCombinations {
            XCTAssertTrue(IPValidator.isValidIPAndPort(ip: ip, port: port), 
                         "IP '\(ip)' and port '\(port)' should be valid")
        }
    }
    
    func testInvalidIPAndPortCombinations() {
        // Test invalid IP and port combinations
        let invalidCombinations = [
            ("192.168.1.1", "0"),        // Invalid port
            ("192.168.1.1", "65536"),    // Invalid port
            ("256.1.1.1", "8080"),       // Invalid IP
            ("192.168.01.1", "80"),      // Invalid IP
            ("", "8080"),                 // Empty IP
            ("192.168.1.1", ""),         // Empty port
            ("", ""),                     // Both empty
            ("192.168.1", "8080"),       // Invalid IP
            ("192.168.1.1", "abc")       // Invalid port
        ]
        
        for (ip, port) in invalidCombinations {
            XCTAssertFalse(IPValidator.isValidIPAndPort(ip: ip, port: port), 
                          "IP '\(ip)' and port '\(port)' should be invalid")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceIPv4Validation() {
        // Test performance with many validations
        let testIPs = [
            "192.168.1.1", "10.0.0.1", "172.16.0.1", "127.0.0.1",
            "256.1.1.1", "192.168.01.1", "192.168.1", "192.168.1.1.1"
        ]
        
        measure {
            for _ in 0..<1000 {
                for ip in testIPs {
                    _ = IPValidator.isValidIPv4(ip)
                }
            }
        }
    }
    
    func testPerformancePortValidation() {
        // Test performance with many port validations
        let testPorts = ["80", "443", "8080", "3000", "65535", "0", "65536", "abc"]
        
        measure {
            for _ in 0..<1000 {
                for port in testPorts {
                    _ = IPValidator.isValidPort(port)
                }
            }
        }
    }
}
