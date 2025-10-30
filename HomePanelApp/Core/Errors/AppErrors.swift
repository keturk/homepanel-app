import Foundation
import Security

// MARK: - App Error Protocol

/// Base protocol for all app errors with consistent error handling
protocol AppError: LocalizedError {
    var recoverySuggestion: String? { get }
}

// MARK: - Hub Errors

/// Errors related to hub operations, configuration, and communication
enum HubError: AppError {
    // Connection & Network
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case hubUnreachable(String)
    
    // Configuration
    case invalidConfiguration
    case invalidConnectionString
    case invalidCredentials
    case missingCredentials
    
    // Hub Management
    case hubNotFound(String)
    case hubAlreadyExists(String)
    
    // Device Operations
    case deviceNotFound(String)
    case invalidDeviceData
    case invalidDeviceId(String)

    // Scene Operations
    case sceneNotFound(String)
    case invalidSceneId(String)
    
    // Data Parsing
    case invalidJSON
    case serverError(Int)
    
    // Sync Operations
    case syncFailed(Error)
    
    var errorDescription: String? {
        switch self {
        // Connection & Network
        case .invalidURL:
            return "Invalid URL format"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .hubUnreachable(let id):
            return "Hub '\(id)' is unreachable"
            
        // Configuration
        case .invalidConfiguration:
            return "Invalid hub configuration"
        case .invalidConnectionString:
            return "Invalid connection string"
        case .invalidCredentials:
            return "Invalid credentials for hub"
        case .missingCredentials:
            return "Missing required credentials"
            
        // Hub Management
        case .hubNotFound(let id):
            return "Hub '\(id)' not found"
        case .hubAlreadyExists(let id):
            return "Hub with ID '\(id)' already exists"
            
        // Device Operations
        case .deviceNotFound(let id):
            return "Device '\(id)' not found"
        case .invalidDeviceData:
            return "Invalid device data format"
        case .invalidDeviceId(let id):
            return "Invalid device ID format: '\(id)'"

        // Scene Operations
        case .sceneNotFound(let name):
            return "Scene '\(name)' not found"
        case .invalidSceneId(let id):
            return "Invalid scene ID format: '\(id)'"
            
        // Data Parsing
        case .invalidJSON:
            return "Invalid JSON response"
        case .serverError(let code):
            return "Server error: \(code)"
            
        // Sync Operations
        case .syncFailed(let error):
            return "Failed to sync hub configuration: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL, .invalidConnectionString:
            return "Check the URL format and try again"
        case .invalidResponse, .invalidJSON:
            return "The server response was unexpected. Please try again"
        case .networkError, .hubUnreachable:
            return "Check your network connection and hub status"
        case .invalidConfiguration, .invalidCredentials, .missingCredentials:
            return "Verify your hub configuration settings"
        case .hubNotFound, .deviceNotFound, .sceneNotFound:
            return "Make sure the hub, device, or scene exists and is properly configured"
        case .hubAlreadyExists:
            return "Choose a different hub ID or remove the existing hub first"
        case .invalidDeviceData:
            return "The device data format is not supported. Please contact support"
        case .invalidDeviceId, .invalidSceneId:
            return "The ID format is not valid. This is likely an internal error. Please contact support"
        case .serverError:
            return "The server encountered an error. Please try again later"
        case .syncFailed:
            return "Hub synchronization failed. Check your connection and try again"
        }
    }
}

// MARK: - Security Errors

/// Errors related to security operations, keychain, and PIN management
enum SecurityError: AppError {
    // Keychain Operations
    case itemNotFound
    case duplicateItem
    case unexpectedKeychainError(OSStatus)
    
    // Data Encoding/Decoding
    case encodingError
    case decodingError
    case invalidData
    
    // PIN Operations
    case pinEncodingFailed
    case invalidPIN
    case pinVerificationFailed
    
    var errorDescription: String? {
        switch self {
        // Keychain Operations
        case .itemNotFound:
            return "PIN not found. Please try again."
        case .duplicateItem:
            return "Username already exists. Please choose a different name."
        case .unexpectedKeychainError(let status):
            return "Could not save PIN. Please try again. (Error: \(status))"
            
        // Data Encoding/Decoding
        case .encodingError:
            return "Could not process PIN data. Please try again."
        case .decodingError:
            return "Could not read saved PIN data. Please try again."
        case .invalidData:
            return "Invalid PIN data. Please try again."
            
        // PIN Operations
        case .pinEncodingFailed:
            return "Failed to process PIN. Please try again."
        case .invalidPIN:
            return "Invalid PIN format. Please enter a 6-digit number."
        case .pinVerificationFailed:
            return "PIN verification failed. Please check your PIN and try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .itemNotFound:
            return "Make sure you're entering the correct PIN."
        case .duplicateItem:
            return "Choose a different username that hasn't been used before."
        case .unexpectedKeychainError:
            return "Check your device's security settings and try again."
        case .encodingError, .decodingError, .invalidData, .pinEncodingFailed:
            return "Restart the app and try again. If the problem persists, contact support."
        case .invalidPIN:
            return "Enter a 6-digit numeric PIN."
        case .pinVerificationFailed:
            return "Double-check your PIN and try again. If you've forgotten your PIN, contact support."
        }
    }
}

// MARK: - Timeout Error

/// Error for operations that exceed their timeout limit
struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

// MARK: - Camera Errors

/// Errors related to camera configuration and operations
enum CameraError: AppError {
    case configurationNotFound(String)
    case invalidConfiguration
    case passwordStorageFailed
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .configurationNotFound(let id):
            return "Camera configuration not found for '\(id)'"
        case .invalidConfiguration:
            return "Invalid camera configuration"
        case .passwordStorageFailed:
            return "Failed to store camera password securely"
        case .authenticationFailed:
            return "Camera authentication failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .configurationNotFound:
            return "Add the camera configuration first"
        case .invalidConfiguration:
            return "Check your camera settings and try again"
        case .passwordStorageFailed:
            return "Check your device's security settings and try again"
        case .authenticationFailed:
            return "Verify your camera credentials and network connection"
        }
    }
}
