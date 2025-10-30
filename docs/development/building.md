# Building and Deployment

This guide covers building, testing, and deploying the Home Panel App.

## 🔨 Building

### Xcode Build

**Standard Build**:
```bash
# Build for simulator
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build

# Build for device
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'generic/platform=iOS' build
```

**Release Build**:
```bash
# Build for release
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'generic/platform=iOS' -configuration Release build
```

### Build Configuration

**Debug Configuration**:
- Optimization: None
- Debug Information: DWARF
- Swift Compilation: Debug
- Code Signing: Automatic

**Release Configuration**:
- Optimization: Speed
- Debug Information: DWARF with dSYM
- Swift Compilation: Optimize
- Code Signing: Automatic

### Build Settings

**Target Settings**:
- iOS Deployment Target: 18.2
- Swift Language Version: 6.0
- Bundle Identifier: com.sunfoxinnovations-llc.homepanel
- Version: 1.0.0
- Build: 1

**Architecture Settings**:
- Architectures: arm64
- Valid Architectures: arm64
- Build Active Architecture Only: Yes (Debug), No (Release)

## 🧪 Testing

### Unit Testing

**Run Tests**:
```bash
# Run all tests
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test

# Run specific test
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test -only-testing:HomePanelAppTests/TestName
```

**Test Configuration**:
- Test Target: HomePanelAppTests
- Test Host: HomePanelApp
- Bundle Loader: $(BUILT_PRODUCTS_DIR)/HomePanelApp.app/HomePanelApp
- Test Product Path: $(BUILT_PRODUCTS_DIR)/HomePanelAppTests.xctest

### UI Testing

**UI Test Configuration**:
- Test Target: HomePanelAppUITests
- Test Host: HomePanelApp
- Bundle Loader: $(BUILT_PRODUCTS_DIR)/HomePanelApp.app/HomePanelApp

**UI Test Scenarios**:
- PIN entry and validation
- Alarm state changes
- Settings navigation
- Error handling

### Integration Testing

**Vera Hub Integration**:
- Test with real Vera Hub
- Verify scene execution
- Test alarm state fetching
- Validate error handling

**Network Testing**:
- Test offline scenarios
- Test network errors
- Test timeout handling
- Test retry logic

## 📱 Deployment

### Development Deployment

**Simulator Deployment**:
```bash
# Build and run in simulator
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build
xcrun simctl install booted HomePanelApp.app
xcrun simctl launch booted com.sunfoxinnovations-llc.homepanel
```

**Device Deployment**:
1. Connect device via USB
2. Select device in Xcode
3. Build and run (⌘+R)
4. Trust developer certificate on device

### Production Deployment

**App Store Preparation**:
1. Update version and build numbers
2. Create release build
3. Archive the app
4. Upload to App Store Connect

**Archive Process**:
```bash
# Create archive
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'generic/platform=iOS' -configuration Release archive -archivePath HomePanelApp.xcarchive

# Export for App Store
xcodebuild -exportArchive -archivePath HomePanelApp.xcarchive -exportPath Export -exportOptionsPlist ExportOptions.plist
```

**Export Options**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

## 🔧 Build Scripts

### Cursor Tools

**Compile Check**:
```bash
#!/bin/bash
# cursor_tools/compile_check.sh

cd HomePanelApp
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build > ../cursor_tools/compile_output.log 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    exit 0
else
    echo "❌ Build failed"
    exit 1
fi
```

**Syntax Check**:
```bash
#!/bin/bash
# cursor_tools/check_syntax_errors.sh

cd HomePanelApp
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build 2>&1 | grep -E "(error|warning)" > ../cursor_tools/syntax_errors.log

if [ -s ../cursor_tools/syntax_errors.log ]; then
    echo "❌ Syntax errors found:"
    cat ../cursor_tools/syntax_errors.log
    exit 1
else
    echo "✅ No syntax errors"
    exit 0
fi
```

**Open Xcode**:
```bash
#!/bin/bash
# cursor_tools/open_xcode.sh

open HomePanelApp/HomePanelApp.xcodeproj
```

### Custom Build Scripts

**Build and Test**:
```bash
#!/bin/bash
# build_and_test.sh

echo "🔨 Building Home Panel App..."
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build

if [ $? -eq 0 ]; then
    echo "✅ Build successful"
    echo "🧪 Running tests..."
    xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' test
else
    echo "❌ Build failed"
    exit 1
fi
```

**Clean Build**:
```bash
#!/bin/bash
# clean_build.sh

echo "🧹 Cleaning build folder..."
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp clean

echo "🔨 Building from clean state..."
xcodebuild -project HomePanelApp.xcodeproj -scheme HomePanelApp -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build
```

## 📊 Build Metrics

### Performance Metrics

**Build Time**:
- Debug build: ~30-60 seconds
- Release build: ~60-120 seconds
- Clean build: ~90-180 seconds

**Binary Size**:
- Debug: ~15-20 MB
- Release: ~8-12 MB
- App Store: ~6-10 MB

**Memory Usage**:
- Debug: ~50-100 MB
- Release: ~30-60 MB
- Peak: ~100-200 MB

### Quality Metrics

**Code Coverage**:
- Target: >80%
- Current: ~70%
- Critical paths: >90%

**Static Analysis**:
- SwiftLint: 0 warnings
- Xcode Analyzer: 0 issues
- Memory leaks: 0 detected

## 🔧 Troubleshooting

### Build Issues

**Common Build Errors**:
- Code signing issues
- Deployment target mismatch
- Swift version compatibility
- Missing dependencies

**Solutions**:
```bash
# Clean build folder
xcodebuild clean

# Reset package cache
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm

# Update packages
xcodebuild -resolvePackageDependencies
```

### Deployment Issues

**Code Signing**:
- Check team selection
- Verify provisioning profile
- Update certificates
- Check bundle identifier

**Device Issues**:
- Trust developer certificate
- Check device compatibility
- Verify iOS version
- Check device storage

### Performance Issues

**Build Performance**:
- Use SSD storage
- Increase RAM
- Close unnecessary apps
- Use faster CPU

**Runtime Performance**:
- Profile with Instruments
- Check memory usage
- Monitor CPU usage
- Optimize algorithms

## 📚 Additional Resources

### Apple Documentation

- [App Store Connect](https://developer.apple.com/app-store-connect/)
- [Code Signing](https://developer.apple.com/support/code-signing/)
- [Testing Guide](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

### Build Tools

- [Fastlane](https://fastlane.tools/) - Automation
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style
- [Instruments](https://developer.apple.com/instruments/) - Profiling

---

This building guide provides comprehensive instructions for building, testing, and deploying the Home Panel App. Follow the steps carefully and refer to the troubleshooting section if you encounter any issues.
