# Features Overview

The Home Panel App is organized into feature modules, each containing its own models, services, view models, and views. This modular approach ensures clear separation of concerns and maintainable code.

## 🚀 Core Features

### [Alarm System](Alarm/README.md)
Real-time monitoring and control of Vera Hub alarm systems with advanced multi-PIN security.

**Key Capabilities:**
- Real-time alarm state monitoring (Armed Away, Armed Stay, Armed Night-Stay, Disarmed)
- PIN-protected mode changes with dynamic scene mapping
- Advanced lockout system with prime number delays
- Cross-device synchronization via iCloud Keychain
- Duress PIN support for emergency situations

**Files:**
- [Models](Alarm/Models/README.md) - Alarm states, modes, and PIN data structures
- [Services](Alarm/Services/README.md) - Vera Hub integration and security services
- [ViewModels](Alarm/ViewModels/README.md) - Business logic and state management
- [Views](Alarm/Views/README.md) - SwiftUI user interface components

### [Camera Surveillance](Camera/README.md)
Dynamic camera management and live video streaming with multi-VMS support.

**Key Capabilities:**
- Multi-VMS support (Blue Iris, Frigate, RTSP, MJPEG, Generic Web View)
- Dynamic camera management with user-defined names
- Up to 2 cameras with full CRUD operations
- VMS type selection and adapter pattern architecture
- Master PIN protection for all camera settings
- Real-time configuration management with validation
- Pull-to-refresh and error handling with retry options

**Files:**
- [Models](Camera/Models/README.md) - Camera configuration and credential models
- [Services](Camera/Services/README.md) - Camera configuration and credential management
- [ViewModels](Camera/ViewModels/README.md) - Camera state and configuration logic
- [Views](Camera/Views/README.md) - Camera interface and settings components

### [Automation System](Automation/README.md)
Multi-hub device control and scene management with comprehensive device selection interface.

**Key Capabilities:**
- Interactive control of smart devices (lights, switches, dimmers, sensors, locks)
- Scene activation with single tap
- Multi-hub support (Vera Lite, Edge, Plus)
- Device selection management with dual-pane interface
- Hub and room organization with search and filtering
- Drag-to-order functionality for selected devices
- Adaptive grid layout for different screen sizes
- Real-time device state polling with retry mechanisms
- Notification-based updates for device selection changes
- Placeholder device support for missing or disconnected devices

**Files:**
- [Services](Automation/Services/README.md) - Vera Hub scene and device control services
- [ViewModels](Automation/ViewModels/README.md) - Device state management and automation logic
- [Views](Automation/Views/README.md) - Device cards, automation interface, and settings

### [Hub Integration](Hub/README.md)
Universal hub abstraction layer supporting multiple hub types and protocols.

**Key Capabilities:**
- Protocol-based hub abstraction
- Multi-hub device state management
- Device state caching and synchronization
- Polling service with configurable intervals
- State change event publishing

**Files:**
- [Models](Hub/Models/README.md) - Universal device models and hub protocols
- [Services](Hub/Services/README.md) - Hub management, polling, and state coordination

### [Settings Management](Settings/README.md)
Split-view interface with organized menu system and specialized management interfaces.

**Key Capabilities:**
- Split-view architecture with resizable divider
- Organized menu system with 6 main categories
- Camera management with multi-VMS support
- Device selection management with dual-pane interface
- Hub management (add, edit, remove hubs)
- PIN management (Master PIN and User PINs)
- App configuration and preferences
- Lockout management and reset
- Data export and import
- Save/discard pattern with coordinated state management

**Files:**
- [Views](Settings/Views/README.md) - Settings interface and PIN management components

## 🏗️ Feature Architecture

Each feature follows a consistent structure:

```
Feature/
├── Models/          # Data models and business entities
├── Services/        # Business logic and external integrations
├── ViewModels/      # UI state management and business logic
├── Views/           # SwiftUI user interface components
└── README.md        # Feature-specific documentation
```

## 🔗 Cross-Feature Dependencies

### Shared Services
- **KeychainService**: Secure credential storage (used by Alarm, Camera, Settings)
- **LockoutManager**: Base lockout functionality (used by Alarm, Settings)
- **HubServiceCoordinator**: Multi-hub coordination (used by Automation, Hub, Alarm)
- **RoomMappingService**: Device organization (used by Automation, Hub)
- **StatePublisher**: Event-driven state updates (used by Hub, Automation)

### Modern Service Architecture
- **HubServiceProtocol**: Unified hub service interface (used by Alarm, Automation)
- **UnifiedAlarmService**: Modern alarm service with hub integration
- **Actor-Based Services**: Thread-safe operations (HubManager, PollingService, DeviceStateCache)
- **Event-Driven Updates**: Real-time state synchronization through Combine

### Data Flow
- **Alarm** → **HubServiceProtocol**: Uses unified hub service for scene execution
- **Automation** → **HubServiceProtocol**: Uses unified hub service for device control
- **Camera** → **Settings**: Uses settings for configuration management
- **Settings** → **All**: Manages configuration for all features
- **Hub** → **All**: Provides unified hub abstraction for all features

## 🎯 Design Principles

### Separation of Concerns
Each feature is self-contained with clear boundaries:
- **Models**: Pure data structures with no business logic
- **Services**: Business logic and external integrations
- **ViewModels**: UI state management and user interactions
- **Views**: Declarative UI components

### Dependency Injection
Features depend on protocols, not concrete implementations:
- Enables easy testing with mocks
- Allows for different implementations
- Promotes loose coupling

### Error Handling
Consistent error handling across all features:
- User-friendly error messages
- Retry mechanisms for network operations
- Graceful degradation when services are unavailable

## 📊 Feature Status

| Feature | Status | Description |
|---------|--------|-------------|
| **Alarm System** | ✅ Complete | Fully functional with advanced security and real-time monitoring |
| **Camera Surveillance** | ✅ Complete | Multi-VMS support with Blue Iris fully implemented, adapter pattern ready for other VMS types |
| **Automation System** | ✅ Complete | Multi-hub device control with comprehensive device selection |
| **Hub Integration** | ✅ Complete | Universal hub abstraction with actor-based architecture |
| **Settings Management** | ✅ Complete | Split-view interface with organized menu system |
| **Security System** | ✅ Complete | Multi-PIN authentication with lockout protection |
| **Device Selection** | ✅ Complete | Comprehensive device and scene selection interface |

## 🔮 Future Features

### Planned Enhancements
- **Recording Controls**: Playback and motion detection for cameras
- **Push Notifications**: Alarm event notifications
- **Widgets**: Home screen widgets for quick access
- **Apple Watch**: Companion app for quick control
- **Voice Control**: Siri integration for hands-free operation

### Technical Improvements
- **Offline Mode**: Local state caching for offline operation
- **Batch Operations**: Multiple state changes in single operation
- **Advanced Analytics**: Usage statistics and performance metrics
- **Custom Scenes**: User-defined automation scenes

## 📚 Documentation

Each feature contains comprehensive documentation:
- **Architecture**: Design patterns and component relationships
- **API Reference**: Service methods and data models
- **Usage Examples**: Code samples and implementation patterns
- **Testing**: Unit and integration testing strategies
- **UI Reference**: Complete UI documentation available at [UI Documentation](../../../docs/ui-documentation.md)

## 🔗 Navigation

- **[Alarm System](Alarm/README.md)** - Security and alarm control
- **[Camera Surveillance](Camera/README.md)** - Live video streaming
- **[Automation System](Automation/README.md)** - Smart device control
- **[Hub Integration](Hub/README.md)** - Multi-hub coordination
- **[Settings Management](Settings/README.md)** - Configuration interface
- **[Main App Architecture](../README.md)** - Overall app architecture
- **[Core Infrastructure](../Core/README.md)** - Shared infrastructure
- **[Shared Components](../Shared/README.md)** - Reusable components

---

This feature-based architecture ensures maintainable, testable, and scalable code while providing a clear separation of concerns for each major app capability.
