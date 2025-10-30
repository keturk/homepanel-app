# Home Panel App - Integration & Development Documentation

This directory contains integration guides and development documentation for the Home Panel App. For code-specific documentation, see the README files embedded within the codebase structure.

## 📚 Documentation Index

### Integration Guides
- [Vera Hub API](integration/vera-hub-api.md) - Vera Hub integration and API reference

### Development Guides
- [Setup](development/setup.md) - Initial setup and configuration
- [Building](development/building.md) - Build and deployment
- [Testing](development/testing.md) - Testing strategy and best practices
- [Scripts](development/scripts.md) - Development utilities and scripts

## 🔗 Code Documentation

For comprehensive code documentation, refer to the feature-oriented README files:

- **[Main App Architecture](../HomePanelApp/README.md)** - Overall app architecture and design patterns
- **[Features Overview](../HomePanelApp/Features/README.md)** - All app features and capabilities
- **[Core Infrastructure](../HomePanelApp/Core/README.md)** - Core services and shared models
- **[Shared Components](../HomePanelApp/Shared/README.md)** - Reusable components and utilities

## 🤖 AI Context

For AI tools and external assistance:
- **[PROJECT_CONTEXT.md](../PROJECT_CONTEXT.md)** - Comprehensive standalone document for AI tools

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd home_panel
   ```

2. **Open in Xcode**
   ```bash
   open HomePanelApp/HomePanelApp.xcodeproj
   ```

3. **Build and run**
   - Select target device or simulator
   - Press ⌘+R to build and run

4. **Configure**
   - Set Vera Hub IP in Settings
   - Configure your Master PIN and User PINs
   - Add Blue Iris camera configurations as needed

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │   ViewModels    │    │    Services     │
│                 │    │                 │    │                 │
│ • AlarmTabView  │◄──►│ • AlarmViewModel│◄──►│ • MultiHubAlarm │
│ • CameraWebView │    │ • CameraVM      │    │ • PINService    │
│ • AutomationTab │    │ • AutomationVM  │    │ • KeychainSvc   │
│ • SettingsView  │    │ • SettingsVM    │    │ • CameraConfig  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Data Models   │
                    │                 │
                    │ • AlarmState    │
                    │ • PINData       │
                    │ • Device        │
                    └─────────────────┘
```

## 📋 Project Status

- ✅ **Alarm System** - Complete with UnifiedAlarmService and HubServiceProtocol integration
- ✅ **Camera Surveillance** - Multi-VMS support with adapter pattern, user-defined names, and VMS selection
- ✅ **PIN Security** - Multi-PIN system with Master PIN and User PIN support
- ✅ **Lockout System** - Advanced prime number delay protection
- ✅ **Automation System** - Multi-hub device control with HubServiceProtocol integration
- ✅ **Hub Integration** - Universal hub abstraction with actor-based architecture
- ✅ **Settings Management** - Comprehensive configuration and administration
- ✅ **Device Selection** - Comprehensive device and scene selection interface
- 📋 **Recording Controls** - Planned for future releases

## 🔧 Development Tools

- **Xcode**: 16.4+ (iOS 18.2+ target)
- **Swift**: 6.0
- **Architecture**: MVVM with modern dependency injection
- **UI Framework**: SwiftUI
- **Concurrency**: Mixed patterns with @MainActor coordinators and actor-based services
- **Hub Integration**: HubServiceProtocol with HubServiceCoordinator
- **Camera Integration**: CameraServiceProtocol with VMS adapters (Blue Iris, Frigate, etc.)
- **Service Architecture**: Lazy initialization with factory methods

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Please read [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines and code standards.
