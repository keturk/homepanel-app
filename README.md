# Home Panel App

[![iOS](https://img.shields.io/badge/iOS-18.2+-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat&logo=swift)](https://swift.org/)
[![Xcode](https://img.shields.io/badge/Xcode-16.4+-blue.svg?style=flat&logo=xcode)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20iPadOS-lightgrey.svg?style=flat)](https://developer.apple.com/ios/)

A modern iOS home automation application built with SwiftUI for controlling Vera Hub alarm systems and camera surveillance. Features advanced multi-PIN security, real-time state monitoring, and live video streaming from multiple sources.

## ✨ Key Features

- **🔐 Advanced Security**: Multi-PIN system with Master PIN and User PINs
- **🚨 Alarm Control**: Real-time Vera Hub alarm state management
- **📹 Camera Surveillance**: Live video streaming with Blue Iris integration
- **🔒 Lockout Protection**: Prime number delay system with persistent lockout state
- **🚗 Traffic Estimates**: Real-time travel time estimates to favorite destinations
- **📱 Modern UI**: SwiftUI with responsive design for iPhone and iPad
- **🌐 Local Network**: Secure local-only communication
- **✅ Comprehensive Testing**: 148+ unit tests covering all core functionality

## 📸 Screenshots

### Main Features

<table>
  <tr>
    <td width="33%">
      <img src="snapshots/Alarm Tab.png" alt="Alarm Control" width="100%"/>
      <p align="center"><b>Alarm Control</b><br/>Multi-mode alarm control with PIN entry and traffic estimates</p>
    </td>
    <td width="33%">
      <img src="snapshots/Automation Tab.png" alt="Automation" width="100%"/>
      <p align="center"><b>Automation</b><br/>Device and scene control organized by rooms</p>
    </td>
    <td width="33%">
      <img src="snapshots/Cameras Tab.png" alt="Cameras" width="100%"/>
      <p align="center"><b>Live Cameras</b><br/>Multi-camera surveillance with Blue Iris integration</p>
    </td>
  </tr>
</table>

### Settings & Configuration

<table>
  <tr>
    <td width="50%">
      <img src="snapshots/Settings - Alarm Users.png" alt="PIN Management" width="100%"/>
      <p align="center"><b>PIN Management</b><br/>Master PIN and User PIN configuration</p>
    </td>
    <td width="50%">
      <img src="snapshots/Settings - Automation Hubs.png" alt="Hub Management" width="100%"/>
      <p align="center"><b>Hub Management</b><br/>Configure Vera and other automation hubs</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="snapshots/Settings - Devices and Scenes.png" alt="Device Selection" width="100%"/>
      <p align="center"><b>Device Selection</b><br/>Select and organize devices by hub and room</p>
    </td>
    <td width="50%">
      <img src="snapshots/Settings - Cameras.png" alt="Camera Settings" width="100%"/>
      <p align="center"><b>Camera Settings</b><br/>Configure camera systems and credentials</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <img src="snapshots/Settings - Favorite Destinations.png" alt="Destinations" width="100%"/>
      <p align="center"><b>Favorite Destinations</b><br/>Manage locations for traffic estimates</p>
    </td>
  </tr>
</table>

## 🚀 Quick Start

### Prerequisites

- **Xcode**: 16.4+ (Current: 16.4)
- **iOS**: 18.2+ (Current: 18.7.1)
- **Swift**: 6.0
- **Vera Hub**: Connected to your local network
- **Camera System**: Blue Iris, Frigate, or other VMS (optional)

### Installation

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
   - Select your target device or simulator
   - Press ⌘+R to build and run

### Initial Configuration

1. **Set Vera Hub IP**
   - Open Settings tab
   - Enter your Vera Hub IP address (e.g., 192.168.1.100)

2. **Configure Security**
   - Set your 6-digit Master PIN
   - Add User PINs for family members
   - Test alarm mode changes

3. **Camera Features** ✅ **Production Ready**
   - **Multi-VMS Support**: Blue Iris (fully implemented), Frigate, RTSP, MJPEG, Generic Web View (adapter pattern ready)
   - **Dynamic Camera Management**: Up to 2 cameras with user-defined names
   - **VMS Type Selection**: Choose camera system type in settings
   - **Master PIN Protection**: All camera settings require Master PIN verification
   - **Secure Credential Storage**: Camera passwords stored in iOS Keychain
   - **Auto-credential Embedding**: Seamless login with embedded credentials
   - **Real-time Configuration**: IP address, port, username, and password management
   - **Error Handling**: User-friendly error messages with retry options
   - **Pull-to-refresh**: Manual refresh capability for camera feeds
   - **Full CRUD Operations**: Add, edit, delete camera configurations
   - **Adapter Pattern**: Clean separation between generic interfaces and VMS-specific implementations
   - **Deprecated Methods**: Legacy "Iris One"/"Iris Two" naming replaced with user-defined names
   
   *📝 Camera features section updated: January 2025 - Multi-VMS support with adapter pattern architecture*

## 🏗️ Architecture

Built with modern iOS development practices:

- **SwiftUI**: Declarative UI framework with modern design patterns
- **MVVM**: Clean separation of concerns with @MainActor ViewModels
- **Dependency Injection**: Protocol-based architecture with DependencyContainer
- **Async/Await**: Modern Swift concurrency with actor-based services
- **Keychain**: Secure credential storage with iCloud Keychain sync
- **Split-View Interface**: Modern settings with resizable panes and organized menu system
- **Multi-VMS Support**: Adapter pattern for camera systems (Blue Iris, Frigate, RTSP, MJPEG)
- **Multi-Hub Support**: Universal hub abstraction with Vera Hub integration
- **Event-Driven Updates**: Real-time UI synchronization through Combine publishers
- **Actor-Based Architecture**: Thread-safe services with modern concurrency patterns

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │   ViewModels    │    │    Services     │
│                 │    │                 │    │                 │
│ • AlarmTabView  │◄──►│ • AlarmViewModel│◄──►│ • UnifiedAlarm  │
│ • CameraWebView │    │ • CameraVM      │    │ • CameraConfig  │
│ • SettingsSplitView │ • AutomationVM  │    │ • HubService   │
│ • DeviceSelection │  │ • SettingsContext│   │ • KeychainSvc   │
│ • AutomationTabView│  │ • PINManagementVM│   │ • SceneService  │
│ • PINEntryView   │    │ • LockoutVM     │    │ • LockoutMgr    │
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
                    │ • CameraConfig  │
                    └─────────────────┘
```

## 📚 Documentation

The project uses a feature-oriented documentation structure with README files embedded within the codebase:

### Code Documentation
- **[Main App Architecture](HomePanelApp/README.md)** - Overall app architecture and design patterns
- **[Features Overview](HomePanelApp/Features/README.md)** - All app features and capabilities
- **[Core Infrastructure](HomePanelApp/Core/README.md)** - Core services and shared models
- **[Shared Components](HomePanelApp/Shared/README.md)** - Reusable components and utilities
- **[Settings Management](HomePanelApp/Features/Settings/README.md)** - Split-view settings architecture
- **[Camera System](HomePanelApp/Features/Camera/README.md)** - Multi-VMS camera management
- **[Automation System](HomePanelApp/Features/Automation/README.md)** - Device selection and control

### Integration & Development
- **[Integration Guides](docs/README.md)** - External API integration and development guides
- **[Development Tools](docs/development/)** - Setup, building, testing, and development scripts

### AI Context
- **[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)** - Comprehensive standalone document for AI tools

### User Interface
- **[UI Documentation](docs/ui-documentation.md)** - Complete UI reference covering all screens, dialogs, and navigation flows

## 🔧 Development

### Building

```bash
# Compile check
./scripts/compile_check.sh

# Run all tests
./scripts/run_tests.sh

# Open in Xcode
./scripts/open_xcode.sh

# Check syntax errors
./scripts/check_syntax_errors.sh
```

### Testing

The app includes **148+ comprehensive unit tests** covering all core functionality:

**Test Coverage**:
- **Alarm System** (40+ tests): State management, mode changes, PIN validation
- **Security** (30+ tests): PIN hashing, lockout manager, master PIN operations
- **Hub Integration** (25+ tests): HubScopedID, device management, scene execution
- **Camera System** (20+ tests): Configuration, credential storage, VMS adapters
- **Data Models** (20+ tests): Serialization, validation, business logic
- **Utilities** (13+ tests): IP validation, destination store, favorite destinations

**Running Tests**:
```bash
# Run all tests via script
./scripts/run_tests.sh

# Or via xcodebuild
xcodebuild test -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPhone 17'

# Or in Xcode
# Press Cmd+U to run all tests
```

**Test Quality**:
- Protocol-based mocking for isolation
- Async/await test patterns
- Comprehensive edge case coverage
- Performance benchmarks included

### Code Style

- Follow Swift naming conventions
- Use `@MainActor` for UI-related classes
- Implement proper error handling
- Add documentation comments
- Use async/await for network operations

## 🛡️ Security

- **Local Network Only**: No external network communication
- **Keychain Storage**: All credentials stored securely
- **PIN Hashing**: Secure PIN storage with salt
- **Lockout Protection**: Advanced brute force protection with persistent state

## 📋 Requirements

### System Requirements
- iOS 18.2+ (Current: 18.7.1)
- Xcode 16.4+ (Current: 16.4)
- Swift 6.0
- Local network access

### Hardware Requirements
- Vera Hub (for alarm control)
- Blue Iris, Frigate, or other VMS (for camera surveillance)
- iPad recommended for optimal experience

## 🚧 Roadmap

- [x] **Alarm System**: Complete with advanced security and real-time monitoring
- [x] **Camera Surveillance**: Multi-VMS support with dynamic camera management
- [x] **Automation System**: Multi-hub device control with device selection interface
- [x] **Hub Integration**: Universal hub abstraction with state management
- [x] **Settings Management**: Split-view interface with organized menu system
- [x] **Device Selection**: Comprehensive device and scene selection interface
- [ ] **Recording Controls**: Playback and motion detection for cameras
- [ ] **Push Notifications**: Alarm event notifications
- [ ] **Widgets**: Home screen widgets for quick access
- [ ] **Apple Watch**: Companion app for quick control

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code style and conventions
- Pull request process
- Testing requirements
- Development workflow

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions and support:

- Check the [documentation](docs/) for detailed guides
- Review [known issues](docs/development/testing.md#known-issues)
- Open an issue for bugs or feature requests

---

**Built with ❤️ using SwiftUI and modern iOS development practices.**
