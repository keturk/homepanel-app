# Debug Utilities

Centralized debug logging system with feature-based toggles for the Home Panel App.

## DebugLogger

The DebugLogger provides a unified logging interface with feature-specific toggles and semantic log levels.

### Usage

**Basic Logging:**
```swift
DebugLogger.log("Operation started", feature: .camera)
DebugLogger.success("Operation completed", feature: .camera)
DebugLogger.error("Operation failed: \(error)", feature: .camera)
DebugLogger.warning("Potential issue detected", feature: .camera)
```

**Feature Flags:**
- `.alarm` - Alarm system operations
- `.camera` - Camera operations
- `.common` - Common/shared functionality
- `.settings` - Settings management
- `.automation` - Automation and device control
- `.hubService` - Hub service operations

### Rules

❌ **Never use:**
```swift
print("Debug message")
```

✅ **Always use:**
```swift
DebugLogger.log("Debug message", feature: .camera)
```

### Log Levels

- **log()**: General information and debug messages
- **success()**: Successful operations (✅ emoji)
- **error()**: Errors and failures (❌ emoji)
- **warning()**: Warnings and potential issues (⚠️ emoji)
- **lockout()**: Security lockout events (🔒 emoji)
- **timer()**: Timer and countdown events (⏰ emoji)
- **stateChange()**: State change events (🔄 emoji)

### Output Format

```
🔍 [HH:mm:ss.SSS] [FileName.swift:123] Debug message
✅ [HH:mm:ss.SSS] [FileName.swift:124] Success message
❌ [HH:mm:ss.SSS] [FileName.swift:125] Error message
```

### Enabling/Disabling Logs

Toggle feature-specific logging in DebugLogger.swift:

```swift
enum FeatureFlags {
    static let camera: Bool = true  // Enable camera logs
    static let alarm: Bool = false  // Disable alarm logs
}
```

## Files

- **DebugLogger.swift** - Main logging utility with feature flags
