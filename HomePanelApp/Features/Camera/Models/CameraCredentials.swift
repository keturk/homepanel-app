import Foundation

// MARK: - Camera Credentials Model

/// Represents stored credentials for a camera
public struct CameraCredentials: Codable {
    let cameraId: String
    let password: String              // Will be stored encrypted in Keychain
    let lastUpdated: Date
    
    // MARK: - Initialization
    
    public init(cameraId: String, password: String) {
        self.cameraId = cameraId
        self.password = password
        self.lastUpdated = Date()
    }
    
}
