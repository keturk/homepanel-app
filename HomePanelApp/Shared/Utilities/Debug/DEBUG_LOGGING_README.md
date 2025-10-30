# Feature-Based Debug Logging System

## Overview

This app uses a centralized debug logging system that allows you to enable/disable debug statements for specific features. This makes it much easier to focus on debugging one feature at a time without getting cluttered by debug logs from other features.

## How to Enable/Disable Debug Logs

Open [DebugLogger.swift](DebugLogger.swift) and modify the feature flags in the `Feature` enum:

```swift
enum Feature {
    static var alarm: Bool = true      // Alarm feature debug logs
    static var camera: Bool = true     // Camera feature debug logs (user-defined camera names)
    static var common: Bool = true     // Common/shared functionality (always shown by default)
    static var settings: Bool = true   // Settings feature debug logs
    static var automation: Bool = true // Automation feature debug logs
}
```

### Example: Testing Camera Tabs Only

If you want to test the camera tabs without seeing Alarm debug logs:

```swift
enum Feature {
    static var alarm: Bool = false     // ❌ Hide alarm logs
    static var camera: Bool = true     // ✅ Show camera logs
    static var common: Bool = true     // ✅ Keep common functionality logs
    static var settings: Bool = false  // ❌ Hide settings logs
    static var automation: Bool = false // ❌ Hide automation logs
}
```

### Example: Testing Alarm Feature Only

If you want to focus on the Alarm feature:

```swift
enum Feature {
    static var alarm: Bool = true      // ✅ Show alarm logs
    static var camera: Bool = false    // ❌ Hide camera logs
    static var common: Bool = true     // ✅ Keep common functionality logs
    static var settings: Bool = false  // ❌ Hide settings logs
    static var automation: Bool = false // ❌ Hide automation logs
}
```

## Feature Categories

### 🚨 Alarm (`\.alarm`)
- Alarm mode changes (Home, Away, Disarm, etc.)
- Alarm state refreshing
- Scene map management
- Alarm-specific PIN verification
- Countdown timers

### 📹 Camera (`\.camera`)
- Camera tab initialization (user-defined camera names)
- Web view loading
- Camera configuration
- URL building with credentials

### 🔧 Common (`\.common`)
- Master PIN entry and verification
- User PIN management
- Keychain operations
- Lockout management
- Shared utilities

### ⚙️ Settings (`\.settings`)
- Settings view operations
- Configuration changes
- (To be implemented)

### 🤖 Automation (`\.automation`)
- Automation/scene operations
- (To be implemented)

## Adding Debug Logs to Your Code

### Basic Usage

```swift
// Log a debug message
DebugLogger.log("Camera view initialized", feature: \.camera)

// Log a success message
DebugLogger.success("Configuration saved", feature: \.settings)

// Log an error
DebugLogger.error("Failed to load data: \(error)", feature: \.alarm)

// Log a warning
DebugLogger.warning("Scene map is empty", feature: \.alarm)

// Log lockout information
DebugLogger.lockout("Locked out until \(date)", feature: \.common)

// Log timer/countdown information
DebugLogger.timer("Countdown started - 5 seconds", feature: \.alarm)

// Log state changes
DebugLogger.stateChange("State changed from \(old) to \(new)", feature: \.alarm)
```

### Choosing the Right Feature Flag

- Use `\.alarm` for alarm-specific operations
- Use `\.camera` for camera-specific operations
- Use `\.common` for shared functionality like:
  - Master PIN operations
  - Keychain operations
  - Lockout management
  - Any utility used across multiple features
- Use `\.settings` for settings-related operations
- Use `\.automation` for automation/scene operations

## Benefits

1. **Focused Debugging**: Only see logs relevant to what you're testing
2. **Less Console Clutter**: Hide irrelevant debug statements
3. **Better Performance**: Disabled logs are completely skipped (compiler optimized)
4. **Easy Toggle**: Change one line to enable/disable entire feature's logs
5. **Source Location**: All logs automatically include file name and line number

## Debug Log Output Format

All debug logs follow this format:
```
[emoji] [FileName.swift:line] Message
```

Examples:
```
🔍 [CameraViewModel.swift:127] CameraViewModel (iris_one) - buildURLWithCredentials: http://192.168.1.100
✅ [AlarmViewModel.swift:310] service.setAlarmMode completed successfully
❌ [PINManagementService.swift:51] Keychain Error: Item not found
⚠️ [AlarmViewModel.swift:327] Scene map is empty - alarm mode changes will fail
🔒 [AlarmViewModel.swift:103] Cannot change mode - locked out until 2m 30s
⏰ [AlarmViewModel.swift:230] Countdown timer started - 5 seconds
🔄 [AlarmViewModel.swift:282] State changed from unknown to disarmed
```

## Migration Notes

All existing debug statements have been migrated to use the new `DebugLogger` system:
- ✅ AlarmViewModel and AlarmDebugUtils
- ✅ CameraViewModel and CameraTabView
- ✅ PINManagementService (common functionality)

Future features should use this system from the start.
