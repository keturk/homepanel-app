import Foundation

// MARK: - Dependency Container

/// A simple dependency injection container for managing service dependencies
@MainActor
public class DependencyContainer {
    
    // MARK: - Shared Instance
    
    // Create a single shared PINManagementService instance
    private static let sharedPINService = {
        DebugLogger.log("🔍 Creating shared PINManagementService instance", feature: .common)
        return PINManagementService()
    }()
    public static let shared = {
        DebugLogger.log("🔍 Creating DependencyContainer.shared", feature: .common)
        return DependencyContainer(config: AppConfiguration(pinService: sharedPINService))
    }()
    
    // MARK: - Configuration
    
    private let config: AppConfigurationProtocol
    
    // MARK: - Services (Lazy initialization)
    
    /// Custom URLSession with extended timeouts for Vera Hub communication
    /// - 30s request timeout: Handles very slow hub responses during device operations
    /// - 60s resource timeout: Accommodates complex scene fetching and device state updates
    /// - Benefits over URLSession.shared: Consistent timeout behavior across all services
    private lazy var sharedURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeoutConfiguration.standardRequest
        configuration.timeoutIntervalForResource = TimeoutConfiguration.resourceDownload
        return URLSession(configuration: configuration)
    }()
    
    private lazy var sceneService: SceneServiceProtocol = {
        SceneServiceCoordinator(hubService: hubService, session: sharedURLSession)
    }()

    private lazy var alarmService: VeraHubAlarmServiceProtocol = {
        UnifiedAlarmService(hubService: hubService, config: config)
    }()
    
    
    private lazy var keychainService: KeychainServiceProtocol = {
        KeychainService.shared
    }()
    
    private lazy var pinManagementService: any PINManagementServiceProtocol = {
        Self.sharedPINService
    }()
    
    lazy var cameraConfigService: CameraConfigServiceProtocol = {
        CameraConfigService(
            userDefaults: .standard,
            keychainService: keychainService
        )
    }()
    
    lazy var hubConfigStore: HubConfigurationStore = {
        HubConfigurationStore()
    }()

    lazy var destinationStore: DestinationStore = {
        DestinationStore(keychainService: keychainService)
    }()

    lazy var trafficService: TrafficService = {
        TrafficService()
    }()

    private var _hubService: HubServiceProtocol?
    
    var hubService: HubServiceProtocol {
        if let service = _hubService {
            return service
        }
        let service = HubServiceCoordinator(session: sharedURLSession)
        _hubService = service
        return service
    }
    
    // MARK: - Initialization
    
    internal init(config: AppConfigurationProtocol) {
        self.config = config
    }
    
    internal func setHubService(_ service: HubServiceProtocol) {
        self._hubService = service
    }
    
    // MARK: - Service Access
    
    public func getSceneService() -> SceneServiceProtocol {
        return sceneService
    }
    
    public func getAlarmService() -> VeraHubAlarmServiceProtocol {
        return alarmService
    }
    
    
    internal func getConfig() -> AppConfigurationProtocol {
        return config
    }
    
    internal func getCameraConfigService() -> CameraConfigServiceProtocol {
        return cameraConfigService
    }
    
    internal func getKeychainService() -> KeychainServiceProtocol {
        return keychainService
    }
    
    internal func getHubService() -> HubServiceProtocol {
        return hubService
    }
    
    internal func getHubConfigStore() -> HubConfigurationStore {
        return hubConfigStore
    }
    
    internal func getPINManagementService() -> any PINManagementServiceProtocol {
        return pinManagementService
    }
    
    internal func getPINService() -> PINManagementService {
        return pinManagementService as! PINManagementService
    }

    internal func getCameraConfigService() -> CameraConfigService {
        return cameraConfigService as! CameraConfigService
    }

    internal func getDestinationStore() -> DestinationStore {
        return destinationStore
    }

    internal func getTrafficService() -> TrafficService {
        return trafficService
    }

    // MARK: - Factory Methods for Testing
    
    /// Creates a new instance of AlarmViewModel with injected dependencies
    internal func createAlarmViewModel() -> AlarmViewModel {
        return AlarmViewModel(
            config: config,
            sceneService: sceneService,
            alarmService: alarmService,
            pinService: pinManagementService
        )
    }

    /// Creates a new instance of AlarmViewModel with custom lockout service
    internal func createAlarmViewModel(lockoutService: AlarmLockoutService) -> AlarmViewModel {
        return AlarmViewModel(
            config: config,
            sceneService: sceneService,
            alarmService: alarmService,
            pinService: pinManagementService,
            lockoutService: lockoutService
        )
    }
    
    /// Creates a new instance of AutomationViewModel with injected dependencies
    internal func createAutomationViewModel() -> AutomationViewModel {
        return AutomationViewModel(
            hubService: hubService,
            appConfig: config
        )
    }
}
