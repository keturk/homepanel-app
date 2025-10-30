import Foundation
import Security
import Combine

// MARK: - PIN Management Service Protocol

/// Protocol defining the interface for PIN management operations
@MainActor
protocol PINManagementServiceProtocol: ObservableObject {
    var userPINs: [PINData] { get }
    var masterPINData: MasterPINData? { get }
    var lastError: SecurityError? { get }
    var errorMessage: String? { get }
    var masterPINLastUsed: Date? { get }
    
    // Master PIN Management
    func setMasterPIN(_ pin: String) -> Bool
    func verifyMasterPIN(_ pin: String) -> Bool
    func changeMasterPIN(oldPIN: String, newPIN: String) -> Bool
    
    // User PIN Management
    func addUserPIN(_ pin: String, name: String) -> Bool
    func removeUserPIN(_ id: UUID) -> Bool
    func verifyUserPIN(_ pin: String) -> Bool
    func verifyAnyPIN(_ pin: String) -> Bool
    func getAllPINs() -> [PINData]
    
    // Lockout Management
    func isLockedOut() -> Bool
    func recordFailedAttempt()
    func recordSuccessfulAttempt()
    func getRemainingLockoutTime() -> String
    func clearLockoutState()
    func getConsecutiveFailures() -> Int
    
    // Error Handling
    func clearError()
}

// MARK: - PIN Management Service

@MainActor
class PINManagementService: ObservableObject, PINManagementServiceProtocol {
    @Published var userPINs: [PINData] = []
    @Published var masterPINData: MasterPINData?
    
    // Delegate lockout management to the shared LockoutManager
    private let lockoutManager: LockoutManager
    
    // Error handling
    @Published var lastError: SecurityError?
    @Published var errorMessage: String?
    
    // Thread safety
    private let queue = DispatchQueue(label: "com.homepanel.pinmanagement", qos: .userInitiated)
    
    private let keychain = KeychainService.shared
    private let masterPINKey = "master_pin_data"
    private let userPINsKey = "user_pins"
    
    
    // Get the last used time for Master PIN
    var masterPINLastUsed: Date? {
        return masterPINData?.lastUsed
    }
    
    init() {
        DebugLogger.log("🔍 PINManagementService init() called - creating new instance", feature: .common)
        DebugLogger.log("🔍 This should NOT create any 'Unnamed PIN' anymore", feature: .common)
        
        // Initialize lockout manager
        self.lockoutManager = LockoutManager(
            lockoutUntilKey: "lockout_until",
            consecutiveFailuresKey: "consecutive_failures",
            debugFeature: .common
        )
        
        // LockoutManager properties are already @Published, so UI will update automatically
        
        loadPINs()
    }
    
    
    // MARK: - Error Handling
    
    private func handleError(_ error: SecurityError) {
        self.lastError = error
        self.errorMessage = error.localizedDescription
        DebugLogger.error("Keychain Error: \(error.localizedDescription)", feature: .common)
        if let recovery = error.recoverySuggestion {
            DebugLogger.log("Recovery: \(recovery)", feature: .common)
        }
    }
    
    func clearError() {
        self.lastError = nil
        self.errorMessage = nil
    }
    
    // MARK: - Master PIN Management
    
    func setMasterPIN(_ pin: String) -> Bool {
        guard isValidPIN(pin) else { 
            handleError(.invalidData)
            return false 
        }
        
        do {
            let newMasterPINData = try MasterPINData(pin: pin)
            queue.sync {
                masterPINData = newMasterPINData
            }
        } catch {
            handleError(.invalidData)
            return false
        }
        
        do {
            try saveMasterPINData()
            clearError()
            return true
        } catch let error as SecurityError {
            handleError(error)
            return false
        } catch {
            handleError(.unexpectedKeychainError(errSecInternalError))
            return false
        }
    }
    
    func verifyMasterPIN(_ pin: String) -> Bool {
        return queue.sync {
            guard let masterData = masterPINData else { return false }
            let result = masterData.verifyPIN(pin)
            
            // Update last used date if verification was successful
            if result {
                masterPINData?.lastUsed = Date()
                do {
                    try saveMasterPINData()
                } catch {
                    // Don't show error for verification, just log it
                    DebugLogger.warning("Failed to save Master PIN last used date: \(error)", feature: .common)
                }
            }

            DebugLogger.log("verifyMasterPIN called - result=\(result)", feature: .common)
            return result
        }
    }
    
    func changeMasterPIN(oldPIN: String, newPIN: String) -> Bool {
        DebugLogger.log("changeMasterPIN called", feature: .common)

        let oldPINValid = verifyMasterPIN(oldPIN)
        let newPINValid = isValidPIN(newPIN)
        DebugLogger.log("verifyMasterPIN result: \(oldPINValid)", feature: .common)
        DebugLogger.log("isValidPIN result: \(newPINValid)", feature: .common)

        guard oldPINValid && newPINValid else {
            DebugLogger.log("Guard failed - oldPIN valid: \(oldPINValid), newPIN valid: \(newPINValid)", feature: .common)
            if !oldPINValid {
                handleError(.itemNotFound)
            } else if !newPINValid {
                handleError(.invalidData)
            }
            return false
        }

        do {
            let newMasterPINData = try MasterPINData(pin: newPIN)
            queue.sync {
                masterPINData = newMasterPINData
            }
        } catch {
            handleError(.invalidData)
            return false
        }

        DebugLogger.success("Master PIN changed successfully", feature: .common)
        DebugLogger.log("User PINs preserved: \(userPINs.count) PINs", feature: .common)
        
        do {
            try saveMasterPINData()
            clearError()
            return true
        } catch let error as SecurityError {
            handleError(error)
            return false
        } catch {
            handleError(.unexpectedKeychainError(errSecInternalError))
            return false
        }
    }
    
    private func saveMasterPINData() throws {
        guard let masterData = masterPINData else {
            throw SecurityError.invalidData
        }
        guard let data = try? JSONEncoder().encode(masterData) else {
            throw SecurityError.encodingError
        }
        try keychain.storeData(key: masterPINKey, value: data, syncable: true)
    }
    
    // MARK: - User PIN Management
    
    func addUserPIN(_ pin: String, name: String = "") -> Bool {
        guard isValidPIN(pin) else { 
            handleError(.invalidData)
            return false 
        }
        
        return queue.sync {
            // Check if name is unique (if name is provided and not empty)
            if !name.isEmpty && userPINs.contains(where: { $0.name == name }) {
                handleError(.duplicateItem)
                return false
            }
            
            do {
                let newPIN = try PINData(pin: pin, name: name)
                userPINs.append(newPIN)
            } catch {
                handleError(.invalidData)
                return false
            }
            
            do {
                try saveUserPINs()
                clearError()
                return true
            } catch let error as SecurityError {
                handleError(error)
                return false
            } catch {
                handleError(.unexpectedKeychainError(errSecInternalError))
                return false
            }
        }
    }
    
    func removeUserPIN(_ id: UUID) -> Bool {
        return queue.sync {
            userPINs.removeAll { $0.id == id }
            
            do {
                try saveUserPINs()
                clearError()
                return true
            } catch let error as SecurityError {
                handleError(error)
                return false
            } catch {
                handleError(.unexpectedKeychainError(errSecInternalError))
                return false
            }
        }
    }
    
    func verifyUserPIN(_ pin: String) -> Bool {
        guard isValidPIN(pin) else { return false }
        
        return queue.sync {
            if let index = userPINs.firstIndex(where: { $0.verifyPIN(pin) }) {
                // Update last used date
                userPINs[index].lastUsed = Date()
                do {
                    try saveUserPINs()
                } catch {
                    // Don't show error for verification, just log it
                    DebugLogger.warning("Failed to save last used date: \(error)", feature: .common)
                }
                return true
            }

            return false
        }
    }

    func verifyAnyPIN(_ pin: String) -> Bool {
        let masterResult = verifyMasterPIN(pin)
        let userResult = verifyUserPIN(pin)

        DebugLogger.log("PIN verification - Master=\(masterResult), User=\(userResult)", feature: .common)
        DebugLogger.log("Master PIN exists: \(masterPINData != nil)", feature: .common)
        DebugLogger.log("User PINs count: \(userPINs.count)", feature: .common)

        return masterResult || userResult
    }
    
    func getAllPINs() -> [PINData] {
        // Return only user PINs since master PIN is now stored separately
        return queue.sync {
            return userPINs
        }
    }
    
    
    // MARK: - Private Methods
    
    private func loadPINs() {
        queue.sync {
            // Load master PIN data
            do {
                let data = try keychain.retrieveData(key: masterPINKey)
                masterPINData = try JSONDecoder().decode(MasterPINData.self, from: data)
            } catch {
                // Set default Master PIN if none exists
                DebugLogger.log("No master PIN found. Setting default Master PIN.", feature: .common)
                do {
                    masterPINData = try MasterPINData(pin: "123456")
                    try saveMasterPINData()
                } catch {
                    DebugLogger.warning("Failed to create or save default master PIN: \(error)", feature: .common)
                }
            }

            // Load user PINs
            do {
                let data = try keychain.retrieveData(key: userPINsKey)
                let loadedPINs = try JSONDecoder().decode([PINData].self, from: data)

                // Filter out invalid PINs (those with empty names) from legacy data
                let validPINs = loadedPINs.filter { !$0.name.isEmpty }

                if validPINs.count < loadedPINs.count {
                    DebugLogger.log("🧹 Cleaned up \(loadedPINs.count - validPINs.count) invalid PIN(s) with empty names from legacy data", feature: .common)
                    userPINs = validPINs
                    // Save the cleaned-up list back to keychain
                    try? saveUserPINs()
                } else {
                    userPINs = validPINs
                }
            } catch {
                // No user PINs found - this is normal, user PINs are only created when explicitly added by the user
                DebugLogger.log("No user PINs found. This is normal - user PINs are only created when explicitly added by the user.", feature: .common)
                DebugLogger.log("🔍 NOT creating any 'Unnamed PIN' - userPINs will be empty array", feature: .common)
                userPINs = []
            }
            
        }
    }
    
    private func saveUserPINs() throws {
        guard let data = try? JSONEncoder().encode(userPINs) else {
            throw SecurityError.encodingError
        }
        try keychain.storeData(key: userPINsKey, value: data, syncable: true)
    }
    
    private func isValidPIN(_ pin: String) -> Bool {
        return pin.count == 6 && pin.allSatisfy { $0.isNumber }
    }
    
    // MARK: - Lockout Management
    
    func isLockedOut() -> Bool {
        return lockoutManager.isLockedOut()
    }
    
    func recordFailedAttempt() {
        lockoutManager.recordFailedAttempt()
    }
    
    func recordSuccessfulAttempt() {
        lockoutManager.recordSuccessfulAttempt()
    }
    
    func getRemainingLockoutTime() -> String {
        return lockoutManager.getRemainingLockoutTime()
    }
    
    // Method to clear all lockout state (for resetting from old version)
    func clearLockoutState() {
        lockoutManager.clearLockoutState()
    }
    
    // Expose lockout state for UI display
    func getConsecutiveFailures() -> Int {
        return lockoutManager.consecutiveFailures
    }
}
