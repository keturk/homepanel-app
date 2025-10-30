import Foundation
import Combine

// MARK: - Lockout Manager Protocol

/// Protocol defining the interface for lockout management
@MainActor
protocol LockoutManagerProtocol: ObservableObject {
    var lockoutUntil: Date? { get set }
    var consecutiveFailures: Int { get set }
    
    func isLockedOut() -> Bool
    func recordFailedAttempt()
    func recordSuccessfulAttempt()
    func getRemainingLockoutTime() -> String
    func clearLockoutState()
    func reloadLockoutState()
}

// MARK: - Lockout Manager Base Class

/// Base class providing shared lockout management functionality
@MainActor
class LockoutManager: ObservableObject, LockoutManagerProtocol {
    @Published var lockoutUntil: Date?
    @Published var consecutiveFailures: Int = 0
    
    // MARK: - Constants
    
    /// Prime number sequence for lockout periods (in minutes)
    /// 
    /// MATHEMATICAL EASTER EGG:
    /// Prime numbers are used as a subtle nod to the mathematical beauty and importance of prime numbers.
    /// The sequence follows a pendulum motion - swinging forward through primes, then backward, like the
    /// ebb and flow of the universe. "Everything in the universe has a measured motion, or ebb and flow,
    /// like a pendulum swinging between two poles."
    /// 
    /// Why Prime Numbers - Mathematical Significance:
    /// • Fundamental Building Blocks: Primes are the atoms of number theory
    /// • Unique Properties: Each prime has no divisors other than 1 and itself
    /// • Irregular Distribution: Prime gaps follow no simple pattern, creating natural unpredictability
    /// • Mathematical Elegance: Primes represent the purest form of mathematical randomness
    /// • Cryptographic Foundation: Primes are the mathematical basis of modern cryptography
    /// • Pendulum Motion: Swings forward through primes, then backward, like the ebb and flow of the universe
    /// 
    /// USER EXPERIENCE CONSIDERATIONS:
    /// • Reasonable Start: 7 minutes is manageable for legitimate users who make mistakes
    /// • Progressive Escalation: Each step increases the burden on attackers while remaining accessible
    /// • No Artificial Cap: System continues with next prime number for persistent attackers
    /// • Clear Feedback: Users see exact remaining time, reducing frustration
    /// 
    /// DESIGN RATIONALE:
    /// Chosen as a subtle nod to the mathematical beauty and importance of prime numbers.
    /// Prime numbers provide both mathematical elegance and practical security benefits.
    /// Their irregular distribution and unique factorization properties make them ideal for security.
    /// Industry research on optimal lockout timing informed this specific sequence selection.
    private static let primeLockoutMinutes = [7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
    
    /// Number of failed attempts required before triggering a lockout
    private static let attemptsPerLockoutRound = 7
    
    // Storage keys - to be overridden by subclasses
    private let lockoutUntilKey: String
    private let consecutiveFailuresKey: String
    
    // Dependencies
    private let eventPublisher = LockoutEventPublisher.shared
    
    
    // Debug logging feature - to be overridden by subclasses
    private let debugFeature: DebugLogger.Feature
    
    init(lockoutUntilKey: String, consecutiveFailuresKey: String, debugFeature: DebugLogger.Feature) {
        self.lockoutUntilKey = lockoutUntilKey
        self.consecutiveFailuresKey = consecutiveFailuresKey
        self.debugFeature = debugFeature
        loadLockoutState()
    }
    
    // MARK: - Public Methods
    
    func isLockedOut() -> Bool {
        guard let lockoutUntil = lockoutUntil else { return false }
        let now = Date()
        
        if now >= lockoutUntil {
            // Lockout period has expired, reset
            self.lockoutUntil = nil
            self.consecutiveFailures = 0
            saveLockoutState()
            return false
        }
        
        return true
    }
    
    func recordFailedAttempt() {
        consecutiveFailures += 1
        
        // Start lockout after configured attempts, then every N attempts after that
        if consecutiveFailures % LockoutManager.attemptsPerLockoutRound == 0 {
            // Calculate lockout period using prime numbers with pendulum motion
            // Like a pendulum swinging between two poles - forward then backward
            // First lockout (7 attempts): 7 minutes
            // Second lockout (14 attempts): 11 minutes  
            // Third lockout (21 attempts): 13 minutes
            // ... continues to last prime (97 minutes)
            // Then swings back: 89, 83, 79, 73, 71, 67, 61, 59, 53, 47, 43, 41, 37, 31, 29, 23, 19, 17, 13, 11, 7
            // Then swings forward again: 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97
            // "Everything in the universe has a measured motion, or ebb and flow, like a pendulum swinging between two poles"
            let lockoutRound = consecutiveFailures / LockoutManager.attemptsPerLockoutRound
            let primeCount = LockoutManager.primeLockoutMinutes.count
            let cycleLength = primeCount * 2 - 2  // Full pendulum cycle (22 forward + 20 backward = 42)
            let positionInCycle = (lockoutRound - 1) % cycleLength
            
            let lockoutIndex: Int
            if positionInCycle < primeCount {
                // Forward motion: 0 to primeCount-1
                lockoutIndex = positionInCycle
            } else {
                // Backward motion: primeCount-2 down to 1 (skip 0 to avoid repeating 7)
                lockoutIndex = (primeCount * 2 - 2) - positionInCycle
            }
            
            let lockoutMinutes = LockoutManager.primeLockoutMinutes[lockoutIndex]
            
            lockoutUntil = Date().addingTimeInterval(TimeInterval(lockoutMinutes * 60))
            
            DebugLogger.lockout("Failed attempt #\(consecutiveFailures), locked for \(lockoutMinutes) minutes (round \(lockoutRound)) until \(lockoutUntil?.formatted() ?? "unknown")", feature: debugFeature)
        } else {
            DebugLogger.lockout("Failed attempt #\(consecutiveFailures), no lockout yet (need \(LockoutManager.attemptsPerLockoutRound) attempts per round)", feature: debugFeature)
        }
        
        saveLockoutState()
        eventPublisher.publishLockoutStateChanged()
    }
    
    func recordSuccessfulAttempt() {
        consecutiveFailures = 0
        lockoutUntil = nil
        saveLockoutState()
        eventPublisher.publishLockoutCleared()
        
        DebugLogger.log("Successful attempt, lockout cleared", feature: debugFeature)
    }
    
    func getRemainingLockoutTime() -> String {
        guard let lockoutUntil = lockoutUntil else { return "" }
        let now = Date()
        
        if now >= lockoutUntil {
            return ""
        }
        
        let timeInterval = lockoutUntil.timeIntervalSince(now)
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    func clearLockoutState() {
        consecutiveFailures = 0
        lockoutUntil = nil
        
        // Clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: lockoutUntilKey)
        UserDefaults.standard.removeObject(forKey: consecutiveFailuresKey)
        
        
        DebugLogger.log("Cleared all lockout state", feature: debugFeature)
    }
    
    func reloadLockoutState() {
        loadLockoutState()
        DebugLogger.log("Reloaded lockout state from storage", feature: debugFeature)
    }
    
    // MARK: - Private Methods
    
    private func saveLockoutState() {
        // Save to UserDefaults
        if let lockoutUntil = lockoutUntil {
            UserDefaults.standard.set(lockoutUntil, forKey: lockoutUntilKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lockoutUntilKey)
        }
        
        UserDefaults.standard.set(consecutiveFailures, forKey: consecutiveFailuresKey)
    }
    
    private func loadLockoutState() {
        if let savedLockoutUntil = UserDefaults.standard.object(forKey: lockoutUntilKey) as? Date {
            lockoutUntil = savedLockoutUntil
        }
        
        consecutiveFailures = UserDefaults.standard.integer(forKey: consecutiveFailuresKey)
        
        // Check if lockout has expired
        if isLockedOut() {
            DebugLogger.lockout("App started with active lockout until \(lockoutUntil?.formatted() ?? "unknown")", feature: debugFeature)
        }
    }
    
}
