# Shared Components

The shared components directory contains reusable UI components, design system elements, and utility functions that are used across all features of the Home Panel App.

## 🎨 Overview

The shared components provide a consistent user experience and code reusability across the entire application, ensuring design consistency and reducing code duplication.

**Current Implementation**: All shared components are fully implemented with comprehensive design system, reusable UI components, and utility functions supporting the entire application.

## 🔧 Core Components

### Design System

Comprehensive design system for consistent UI patterns:

```swift
enum DesignSystem {
    enum Spacing {
        static let nano: CGFloat = 2
        static let micro: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
        static let xxlarge: CGFloat = 32
        static let massive: CGFloat = 40
    }
    
    enum FontSize {
        static let pico: CGFloat = 16
        static let small: CGFloat = 20
        static let medium: CGFloat = 24
        static let large: CGFloat = 32
        static let xlarge: CGFloat = 48
        static let xxlarge: CGFloat = 64
        static let extraLarge: CGFloat = 80
    }
    
    enum CornerRadius {
        static let nano: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xlarge: CGFloat = 24
        static let extraLarge: CGFloat = 35
    }
}
```

### Reusable UI Components

Common UI components used throughout the app:

- **KeypadButton**: Phone-style numeric keypad button
- **PINDisplayView**: Visual PIN entry progress indicator
- **FeatureRow**: Feature description row component
- **LockoutStatusView**: Lockout status indicator
- **PINErrorPopup**: Error message popup for PIN operations

## 🎨 UI Components

### KeypadButton

Phone-style numeric keypad button with letters:

```swift
struct KeypadButton: View {
    let number: Int
    let isEnabled: Bool
    let action: () -> Void
    
    private var letters: String {
        switch number {
        case 2: return "ABC"
        case 3: return "DEF"
        case 4: return "GHI"
        case 5: return "JKL"
        case 6: return "MNO"
        case 7: return "PQRS"
        case 8: return "TUV"
        case 9: return "WXYZ"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.title2)
                    .fontWeight(.semibold)
                if !letters.isEmpty {
                    Text(letters)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.primary)
            .frame(width: 60, height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(30)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}
```

### PINDisplayView

Visual feedback for PIN entry progress:

```swift
struct PINDisplayView: View {
    let enteredCount: Int
    let maxCount: Int = 6
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            ForEach(0..<maxCount, id: \.self) { index in
                Circle()
                    .fill(index < enteredCount ? Color.primary : Color.gray.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
        .padding()
    }
}
```

### FeatureRow

Consistent feature description row:

```swift
struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.small)
    }
}
```

### LockoutStatusView

Lockout status indicator with countdown:

```swift
struct LockoutStatusView: View {
    let lockoutUntil: Date?
    let isLockedOut: Bool
    
    var body: some View {
        if isLockedOut, let lockoutUntil = lockoutUntil {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.red)
                
                Text("System locked until \(lockoutUntil, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(.horizontal, DesignSystem.Spacing.medium)
            .padding(.vertical, DesignSystem.Spacing.small)
            .background(Color.red.opacity(0.1))
            .cornerRadius(DesignSystem.CornerRadius.small)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
```

## 🔧 Utility Functions

### Validation Utilities

Input validation and formatting utilities:

```swift
enum IPValidator {
    static func isValid(_ ipAddress: String) -> Bool {
        let components = ipAddress.components(separatedBy: ".")
        guard components.count == 4 else { return false }
        
        return components.allSatisfy { component in
            guard let number = Int(component) else { return false }
            return number >= 0 && number <= 255
        }
    }
}

enum PINHasher {
    static func hashPIN(_ pin: String, salt: String) throws -> String {
        let data = (pin + salt).data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    static func generateSalt() -> String {
        let saltData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }
}
```

### Debug Utilities

Debug logging and development utilities:

```swift
enum DebugLogger {
    static func log(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        let timestamp = DateFormatter.debugFormatter.string(from: Date())
        print("[\(timestamp)] [\(category.rawValue)] \(message)")
        #endif
    }
    
    static func logError(_ error: Error, category: LogCategory = .error) {
        #if DEBUG
        log("Error: \(error.localizedDescription)", category: category)
        #endif
    }
}

enum LogCategory: String {
    case general = "GENERAL"
    case network = "NETWORK"
    case security = "SECURITY"
    case ui = "UI"
    case error = "ERROR"
}
```

## 🎨 Design System Integration

### Color System

Consistent color usage across the app:

```swift
extension Color {
    static let alarmDisarmed = Color.green
    static let alarmArmedAway = Color.red
    static let alarmArmedStay = Color.orange
    static let alarmArmedNightStay = Color.purple
    static let alarmUnknown = Color.gray
    
    static let buttonPrimary = Color.blue
    static let buttonSecondary = Color.gray
    static let buttonDestructive = Color.red
    static let buttonSuccess = Color.green
}
```

### Typography

Consistent typography system:

```swift
extension Font {
    static let alarmState = Font.system(size: DesignSystem.FontSize.extraLarge, weight: .bold)
    static let alarmMode = Font.system(size: DesignSystem.FontSize.large, weight: .semibold)
    static let pinDisplay = Font.system(size: DesignSystem.FontSize.medium, weight: .medium)
    static let keypadButton = Font.system(size: DesignSystem.FontSize.medium, weight: .semibold)
    static let featureTitle = Font.system(size: DesignSystem.FontSize.medium, weight: .semibold)
}
```

## 🧪 Testing

### Component Testing

Test shared components in isolation:

```swift
func testKeypadButton() {
    let button = KeypadButton(number: 2, isEnabled: true) { }
    
    // Test button properties
    XCTAssertEqual(button.number, 2)
    XCTAssertTrue(button.isEnabled)
}

func testPINDisplayView() {
    let display = PINDisplayView(enteredCount: 3)
    
    // Test display properties
    XCTAssertEqual(display.enteredCount, 3)
    XCTAssertEqual(display.maxCount, 6)
}

func testIPValidator() {
    XCTAssertTrue(IPValidator.isValid("192.168.1.1"))
    XCTAssertTrue(IPValidator.isValid("10.0.0.1"))
    XCTAssertFalse(IPValidator.isValid("256.1.1.1"))
    XCTAssertFalse(IPValidator.isValid("192.168.1"))
    XCTAssertFalse(IPValidator.isValid("invalid"))
}
```

### Integration Testing

Test components with real data:

```swift
func testFeatureRow() {
    let row = FeatureRow(
        icon: "lightbulb.fill",
        title: "Light Control",
        subtitle: "Control your lights"
    )
    
    // Test row properties
    XCTAssertEqual(row.icon, "lightbulb.fill")
    XCTAssertEqual(row.title, "Light Control")
    XCTAssertEqual(row.subtitle, "Control your lights")
}
```

## 🚀 Performance

### Optimization Strategies

- **Component Reusability**: Reduce code duplication
- **Efficient Rendering**: Optimize SwiftUI view performance
- **Memory Management**: Proper cleanup of resources
- **Lazy Loading**: Load components on demand

### Design System Benefits

- **Consistency**: Uniform look and feel
- **Maintainability**: Centralized design changes
- **Accessibility**: Consistent accessibility support
- **Performance**: Optimized component rendering

## 🔮 Future Enhancements

### Planned Features

- **Theme Support**: Dark/light mode themes
- **Customization**: User-customizable components
- **Animation**: Enhanced component animations
- **Accessibility**: Improved accessibility features

### Technical Improvements

- **Component Library**: Expanded component collection
- **Performance**: Further optimization
- **Documentation**: Enhanced component documentation
- **Testing**: Comprehensive component testing

## 📁 File Structure

- **[Components](Components/README.md)** - Reusable UI components
- **[DesignSystem](DesignSystem/README.md)** - Design system and styling
- **[Utilities](Utilities/README.md)** - Helper functions and utilities

## 🔗 Navigation

- **[Main App Architecture](../README.md)** - Overall app architecture
- **[Features Overview](../Features/README.md)** - All app features
- **[Core Infrastructure](../Core/README.md)** - Core services and models

---

The shared components provide a consistent, reusable, and maintainable foundation for the Home Panel App's user interface and utility functions.
