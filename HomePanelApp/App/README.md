# App Entry Point

The App directory contains the application entry point and dependency injection container, providing the foundation for the Home Panel App's architecture and service management.

## 🚀 Overview

The App directory serves as the entry point for the Home Panel App, containing the main app structure, dependency injection setup, and service coordination that powers the entire application.

## 🏗️ Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    App Entry Point Architecture                │
├─────────────────────────────────────────────────────────────────┤
│  HomePanelApp.swift  │  DependencyContainer.swift             │
│  AppConfiguration    │  Service Registration                   │
└─────────────────┬─────────────────┬─────────────────┬───────────┘
                  │                 │                 │
┌─────────────────▼─────────────────▼─────────────────▼───────────┐
│                    Service Dependencies                        │
├─────────────────────────────────────────────────────────────────┤
│  Alarm Services  │  Camera Services  │  Hub Services          │
└─────────────────────────────────────────────────────────────────┘
```

### App Structure

The app follows a modular architecture with clear separation of concerns:

- **HomePanelApp.swift**: Main app entry point and UI structure
- **DependencyContainer.swift**: Service registration and dependency injection
- **Service Protocols**: Abstract interfaces for all services
- **Configuration Management**: App-wide configuration and settings

## 🔧 Core Components

### HomePanelApp

Main SwiftUI app entry point:

```swift
@main
struct HomePanelApp: App {
    @StateObject private var dependencyContainer = DependencyContainer()
    @StateObject private var appConfiguration = AppConfiguration()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dependencyContainer)
                .environmentObject(appConfiguration)
                .onAppear {
                    dependencyContainer.configure()
                }
        }
    }
}
```

**Key Features:**
- Dependency injection setup
- App configuration management
- Environment object distribution
- Service initialization

### DependencyContainer

Modern dependency injection with lazy initialization and factory methods:

```swift
@MainActor
class DependencyContainer {
    private let config: AppConfigurationProtocol
    
    // Lazy service initialization
    private lazy var sharedURLSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeoutConfiguration.standardRequest
        configuration.timeoutIntervalForResource = TimeoutConfiguration.resourceDownload
        return URLSession(configuration: configuration)
    }()
    
    private lazy var sceneService: SceneServiceProtocol = {
        SceneServiceCoordinator(hubService: hubService, session: sharedURLSession)
    }()
    
    private lazy var alarmService: AlarmServiceProtocol = {
        UnifiedAlarmService(hubService: hubService, config: config)
    }()
    
    private lazy var keychainService: KeychainServiceProtocol = {
        KeychainService.shared
    }()
    
    private lazy var pinManagementService: any PINManagementServiceProtocol = {
        PINManagementService()
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
    
    private var _hubService: HubServiceProtocol?
    
    var hubService: HubServiceProtocol {
        if let service = _hubService {
            return service
        }
        let service = HubServiceCoordinator()
        _hubService = service
        return service
    }
    
    // Factory methods for ViewModels
    internal func createAlarmViewModel() -> AlarmViewModel {
        return AlarmViewModel(
            config: config,
            sceneService: sceneService,
            alarmService: alarmService,
            pinService: pinManagementService
        )
    }
}
```

**Modern Service Architecture:**
```swift
// Lazy initialization pattern
private lazy var alarmService: AlarmServiceProtocol = {
    UnifiedAlarmService(hubService: hubService, config: config)
}()

// Hub service with coordinator pattern
var hubService: HubServiceProtocol {
    if let service = _hubService {
        return service
    }
    let service = HubServiceCoordinator()
    _hubService = service
    return service
}
    
    // Camera Services
    cameraConfigService = CameraConfigService(
        keychainService: keychainService
    )
    
    // Hub Services
    hubManager = HubManager()
}
```

## 🔄 Service Dependencies

### Dependency Graph

Services are organized with clear dependencies:

```
AppConfiguration
├── UnifiedAlarmService
├── SceneServiceCoordinator
└── HubManager

KeychainService
├── PINManagementService
├── AlarmLockoutService
├── CameraConfigService
└── HubConfigurationStore

PINManagementService
└── AlarmLockoutService

HubManager
├── DeviceStateCache
├── PollingService
└── StatePublisher
```

### Service Initialization

Ordered service initialization to respect dependencies:

```swift
private func setupServiceDependencies() {
    // 1. Core services first
    keychainService.configure()
    appConfiguration.load()
    
    // 2. Security services
    pinManagementService.configure()
    lockoutService.configure()
    
    // 3. Feature services
    alarmService.configure()
    sceneService.configure()
    cameraConfigService.configure()
    
    // 4. Hub services last
    hubManager.configure()
}
```

## 🎨 UI Structure

### ContentView

Main app interface with tab navigation:

```swift
struct ContentView: View {
    @EnvironmentObject var dependencyContainer: DependencyContainer
    @EnvironmentObject var appConfiguration: AppConfiguration
    
    var body: some View {
        TabView {
            AlarmTabView()
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("Alarm")
                }
            
            CameraTabView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
            
            AutomationTabView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Automation")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .environmentObject(dependencyContainer.alarmService)
        .environmentObject(dependencyContainer.cameraConfigService)
        .environmentObject(dependencyContainer.hubManager)
    }
}
```

### Environment Objects

Service distribution through environment objects:

```swift
extension ContentView {
    private func setupEnvironmentObjects() {
        // Distribute services to child views
        .environmentObject(dependencyContainer.alarmService)
        .environmentObject(dependencyContainer.sceneService)
        .environmentObject(dependencyContainer.pinManagementService)
        .environmentObject(dependencyContainer.lockoutService)
        .environmentObject(dependencyContainer.cameraConfigService)
        .environmentObject(dependencyContainer.hubManager)
    }
}
```

## 🔐 Security Integration

### Master PIN Setup

App-wide Master PIN configuration:

```swift
extension DependencyContainer {
    func setupSecurity() {
        // Check if Master PIN is set
        if !pinManagementService.hasMasterPIN() {
            // Show Master PIN setup flow
            showMasterPINSetup = true
        }
    }
}
```

### Service Security

Secure service initialization:

```swift
private func setupSecureServices() {
    // Initialize services with security context
    pinManagementService = PINManagementService(
        keychainService: keychainService,
        securityLevel: .high
    )
    
    lockoutService = AlarmLockoutService(
        keychainService: keychainService,
        lockoutPolicy: .strict
    )
}
```

## 🧪 Testing

### App Testing

Test app initialization and service setup:

```swift
func testAppInitialization() {
    let app = HomePanelApp()
    let dependencyContainer = DependencyContainer()
    
    dependencyContainer.configure()
    
    XCTAssertNotNil(dependencyContainer.keychainService)
    XCTAssertNotNil(dependencyContainer.alarmService)
    XCTAssertNotNil(dependencyContainer.pinManagementService)
}

func testServiceDependencies() {
    let container = DependencyContainer()
    container.configure()
    
    // Verify service dependencies are properly set
    XCTAssertNotNil(container.pinManagementService)
    XCTAssertNotNil(container.lockoutService)
    XCTAssertNotNil(container.alarmService)
}
```

### Dependency Injection Testing

Test service injection and configuration:

```swift
func testDependencyInjection() {
    let container = DependencyContainer()
    container.configure()
    
    // Test service injection
    let alarmService = container.alarmService
    XCTAssertNotNil(alarmService)
    
    // Test service configuration
    XCTAssertTrue(alarmService.isConfigured)
}
```

## 🚀 Performance

### Optimization Strategies

- **Lazy Loading**: Services initialized on demand
- **Service Pooling**: Reuse service instances
- **Memory Management**: Proper service cleanup
- **Background Processing**: Non-blocking initialization

### Monitoring

- **Initialization Time**: Track app startup performance
- **Service Load**: Monitor service initialization
- **Memory Usage**: Track service memory consumption
- **Error Rates**: Monitor service initialization failures

## 🔮 Future Enhancements

### Planned Features

- **Service Discovery**: Automatic service discovery
- **Configuration Hot Reload**: Runtime configuration updates
- **Service Health Monitoring**: Service health checks
- **Advanced Dependency Injection**: More sophisticated DI patterns

### Technical Improvements

- **Async Initialization**: Asynchronous service setup
- **Service Lifecycle**: Enhanced service lifecycle management
- **Configuration Validation**: Runtime configuration validation
- **Performance Optimization**: Faster app startup

## 📁 Files

- **HomePanelApp.swift** - Main app entry point
- **DependencyContainer.swift** - Dependency injection container

## 🔗 Navigation

- **[Main App Architecture](../README.md)** - Overall app architecture
- **[Features Overview](../Features/README.md)** - All app features
- **[Core Infrastructure](../Core/README.md)** - Core services and models
- **[Shared Components](../Shared/README.md)** - Reusable components

---

The App entry point provides the foundation for the Home Panel App's architecture, service management, and dependency injection system.
