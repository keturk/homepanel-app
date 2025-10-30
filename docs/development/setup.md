# Development Setup

This guide covers the initial setup and configuration for developing the Home Panel App.

## 📋 Prerequisites

### Required Software

- **Xcode**: 16.4 or later (Current: 16.4)
- **iOS**: 18.2 or later (Current: 18.7.1)
- **Swift**: 6.0
- **macOS**: Latest version (for Xcode compatibility)

### Required Hardware

- **Development Device**: Mac with Apple Silicon or Intel processor
- **Test Device**: iPhone or iPad (iOS 18.7.1+)
- **Vera Hub**: Connected to local network (for testing)

### Network Requirements

- **Local Network**: Vera Hub must be accessible on local network
- **IP Address**: Know your Vera Hub IP address (default: 192.168.1.100)
- **Port**: Vera Hub port 3480 must be accessible

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd home_panel
```

### 2. Open in Xcode

```bash
open HomePanelApp/HomePanelApp.xcodeproj
```

### 3. Configure Project Settings

**Bundle Identifier**:
- Current: `com.sunfoxinnovations-llc.homepanel`
- Update if needed for your organization

**Deployment Target**:
- iOS 18.2 (minimum)
- iPad optimized (primary target)
- iPhone compatible

**Code Signing**:
- Automatic signing enabled
- Update team and provisioning profile

### 4. Build and Test

```bash
# Build the project
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build

# Run tests
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test
```

## 🔧 Configuration

### Vera Hub Configuration

**Default Settings**:
- IP Address: 192.168.1.100
- Port: 3480
- Device ID: 7 (Ademco Vista)

**Custom Configuration**:
1. Open the app
2. Go to Settings tab
3. Update Vera Hub IP address
4. Test connection

### PIN Configuration

**Master PIN Setup**:
1. Open Settings tab
2. Go to PIN Management
3. Set Master PIN (6 digits)
4. Add User PINs as needed

**Test PINs**:
- Master PIN: Set during first use
- User PINs: Add family members
- Duress PIN: "387377" (triggers security warning)

## 🧪 Testing Setup

### Simulator Testing

**Recommended Simulator**:
- iPad Pro 13-inch (M4)
- iOS 18.7.1
- Portrait orientation

**Test Scenarios**:
- PIN entry and validation
- Alarm state changes
- Settings persistence
- Error handling

### Device Testing

**Physical Device**:
- Connect to same network as Vera Hub
- Install app via Xcode
- Test with real Vera Hub

**Network Testing**:
- Test with different Vera Hub IPs
- Test network error scenarios
- Test offline behavior

## 🔧 Development Tools

### Development Scripts

**Available Scripts**:
```bash
# Compile check
./scripts/compile_check.sh

# Check syntax errors
./scripts/check_syntax_errors.sh

# Run all tests
./scripts/run_tests.sh

# Open in Xcode
./scripts/open_xcode.sh

# Quick fixes
./scripts/quick_fixes.sh
```

**Usage**:
- Run before committing changes
- Check for compilation errors
- Validate code syntax

### Xcode Configuration

**Recommended Settings**:
- Show line numbers
- Enable code folding
- Show whitespace
- Enable syntax highlighting

**Build Settings**:
- Swift 6.0 language version
- iOS 18.7.1 deployment target
- Debug information format: DWARF
- Optimization level: None (Debug)

## 📱 Device Configuration

### iPad Setup

**Recommended Settings**:
- Enable local network access
- Allow app to access local network
- Enable notifications (future)
- Set appropriate screen brightness

**Accessibility**:
- VoiceOver support enabled
- Dynamic Type support
- High contrast mode support

### Network Configuration

**Vera Hub Network**:
- Static IP recommended (192.168.1.100)
- Port 3480 accessible
- No firewall blocking
- Stable network connection

**Testing Network**:
- Same subnet as Vera Hub
- Reliable WiFi connection
- No VPN interference

## 🔍 Debugging Setup

### Debug Configuration

**Xcode Debugging**:
- Breakpoints on key functions
- Console logging enabled
- Memory debugging enabled
- Network debugging enabled

**Debug Logging**:
```swift
#if DEBUG
print("🔍 DEBUG: \(message)")
#endif
```

**Error Handling**:
- Comprehensive error logging
- User-friendly error messages
- Debug information in console

### Network Debugging

**Vera Hub API Testing**:
```bash
# Test scene list
curl "http://192.168.1.100:3480/data_request?id=user_data"

# Test alarm state
curl "http://192.168.1.100:3480/data_request?id=status&DeviceNum=7&output_format=json"

# Test scene execution
curl "http://192.168.1.100:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=1"
```

**Network Monitoring**:
- Use Charles Proxy for HTTP monitoring
- Monitor network requests
- Check response data
- Verify authentication

## 🚀 Development Workflow

### Daily Development

1. **Start Development**:
   ```bash
   open HomePanelApp/HomePanelApp.xcodeproj
   ```

2. **Make Changes**:
   - Edit Swift files
   - Test in simulator
   - Check syntax errors

3. **Test Changes**:
   ```bash
   ./scripts/compile_check.sh
   ```

4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "feat: description of changes"
   ```

### Code Quality

**Before Committing**:
- Run compilation check
- Test in simulator
- Verify functionality
- Check error handling

**Code Review**:
- Follow Swift conventions
- Add documentation comments
- Test error scenarios
- Verify accessibility

## 🔧 Troubleshooting

### Common Issues

**Build Errors**:
- Check Xcode version compatibility
- Verify deployment target
- Check code signing settings
- Clean build folder

**Runtime Errors**:
- Check network connectivity
- Verify Vera Hub IP
- Check PIN configuration
- Review console logs

**Simulator Issues**:
- Reset simulator
- Check iOS version
- Verify app installation
- Check permissions

### Network Issues

**Vera Hub Connection**:
- Verify IP address
- Check port accessibility
- Test with curl commands
- Check network settings

**Local Network**:
- Ensure same subnet
- Check firewall settings
- Verify WiFi connection
- Test with other devices

## 📚 Additional Resources

### Documentation

- [Architecture Overview](../architecture/overview.md)
- [API Integration](../integration/vera-hub-api.md)
- [Testing Guide](testing.md)
- [Development Scripts](scripts.md)

### External Resources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [iOS Development](https://developer.apple.com/ios/)
- [Vera Hub API](https://wiki.micasaverde.com/index.php/Luup_Requests)

---

This setup guide provides everything needed to start developing the Home Panel App. Follow the steps carefully and refer to the troubleshooting section if you encounter any issues.
