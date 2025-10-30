# Core Configuration

Centralized configuration values for the application.

## TimeoutConfiguration

All network timeout values are centralized in `TimeoutConfiguration.swift`.

### Usage

```swift
// Use centralized timeout values
try await withTimeout(seconds: TimeoutConfiguration.reachabilityCheck) {
    // operation
}
```

### Available Timeouts

- `reachabilityCheck`: 3s - Quick connectivity tests
- `roomMapping`: 15s - Room data fetching
- `automationRoomMapping`: 10s - Automation room loading
- `standardRequest`: 30s - Standard API requests
- `resourceDownload`: 60s - Large file transfers

### Adjusting Timeouts

Edit `TimeoutConfiguration.swift` to adjust timeout values globally.
