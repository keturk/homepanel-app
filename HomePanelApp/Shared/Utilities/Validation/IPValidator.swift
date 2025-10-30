import Foundation

// MARK: - IP Validator Utility

/// A utility class for IP address validation
/// Provides static methods for validating IPv4 addresses
struct IPValidator {
    
    /// Validates if a string is a valid IPv4 address
    /// - Parameter ip: The IP address string to validate
    /// - Returns: `true` if the IP address is valid, `false` otherwise
    ///
    /// A valid IPv4 address must:
    /// - Contain exactly 4 components separated by dots
    /// - Each component must be a number between 0 and 255 (inclusive)
    /// - No leading zeros (except for "0" itself)
    /// - No leading/trailing dots or double dots
    static func isValidIPv4(_ ip: String) -> Bool {
        // Handle empty string
        guard !ip.isEmpty else { return false }

        // Use components(separatedBy:) instead of split() to detect empty components
        // split() omits empty subsequences, which would allow ".192.168.1.1" or "192..168.1.1"
        let components = ip.components(separatedBy: ".")

        // Must have exactly 4 components
        guard components.count == 4 else { return false }

        // Validate each component
        for component in components {
            // Check for empty components (catches leading/trailing dots and double dots)
            guard !component.isEmpty else { return false }

            // Check for leading zeros (except for "0" itself)
            if component.count > 1 && component.hasPrefix("0") {
                return false
            }

            // Parse as integer and validate range
            guard let number = Int(component) else { return false }
            guard number >= 0 && number <= 255 else { return false }
        }

        return true
    }
    
    /// Validates if a string is a valid IPv4 address (alternative implementation)
    /// This version uses a more functional approach with allSatisfy
    /// - Parameter ip: The IP address string to validate
    /// - Returns: `true` if the IP address is valid, `false` otherwise
    static func isValidIPv4Functional(_ ip: String) -> Bool {
        guard !ip.isEmpty else { return false }

        // Use components(separatedBy:) instead of split() to detect empty components
        let components = ip.components(separatedBy: ".")
        guard components.count == 4 else { return false }

        return components.allSatisfy { component in
            guard !component.isEmpty else { return false }
            guard component.count == 1 || !component.hasPrefix("0") else { return false }
            guard let number = Int(component) else { return false }
            return number >= 0 && number <= 255
        }
    }
    
    /// Validates if a string is a valid port number
    /// - Parameter port: The port string to validate
    /// - Returns: `true` if the port is valid, `false` otherwise
    static func isValidPort(_ port: String) -> Bool {
        guard let portNumber = Int(port) else { return false }
        return portNumber > 0 && portNumber <= 65535
    }
    
    /// Validates if a string is a valid IP address and port combination
    /// - Parameters:
    ///   - ip: The IP address string to validate
    ///   - port: The port string to validate
    /// - Returns: `true` if both IP and port are valid, `false` otherwise
    static func isValidIPAndPort(ip: String, port: String) -> Bool {
        return isValidIPv4(ip) && isValidPort(port)
    }
}

// MARK: - Usage Examples
/*
 
 // Basic IP validation
 let isValid = IPValidator.isValidIPv4("192.168.1.1")  // true
 let isInvalid = IPValidator.isValidIPv4("256.1.1.1")  // false
 
 // Port validation
 let validPort = IPValidator.isValidPort("8080")  // true
 let invalidPort = IPValidator.isValidPort("70000")  // false
 
 // Combined validation
 let valid = IPValidator.isValidIPAndPort(ip: "192.168.1.1", port: "8080")  // true
 
 */
