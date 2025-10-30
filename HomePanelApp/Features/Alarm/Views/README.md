# Alarm Views

This directory contains the SwiftUI user interface components for the alarm system, providing an intuitive and secure interface for alarm control and monitoring.

## 🎨 Core Views

### AlarmTabView

Main alarm interface with state display and mode controls.

```swift
struct AlarmTabView: View {
    @StateObject private var viewModel: AlarmViewModel
    @StateObject private var config: AppConfiguration
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            headerSection
            stateDisplaySection
            modeButtonsSection
            footerSection
        }
        .background(backgroundGradient)
        .sheet(isPresented: $viewModel.showPINEntry) {
            PINEntryView(viewModel: viewModel)
        }
    }
}
```

**Key Sections:**
- **Header**: Settings gear icon and lockout status
- **State Display**: Current alarm state with visual feedback
- **Mode Buttons**: 2x2 grid of alarm mode controls
- **Footer**: Last updated timestamp and refresh indicator

### PINEntryView

Secure PIN entry modal with keypad interface.

```swift
struct PINEntryView: View {
    @ObservedObject var viewModel: AlarmViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var enteredPIN = ""
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            headerSection
            pinDisplaySection
            keypadSection
            actionButtonsSection
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.modal)
    }
}
```

**Key Features:**
- 6-digit PIN entry with visual feedback
- Phone-style keypad with letters
- Auto-submit when complete
- Error handling and retry functionality

### ModeButton

Individual alarm mode button component.

```swift
struct ModeButton: View {
    let mode: AlarmMode
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
                Image(systemName: mode.iconName)
                    .font(.system(size: DesignSystem.FontSize.large))
                Text(mode.displayName)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(mode.buttonColor)
            .cornerRadius(DesignSystem.CornerRadius.button)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}
```

## 🎨 UI Components

### State Display

Visual representation of current alarm state:

```swift
private var stateDisplaySection: some View {
    VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
        Image(systemName: viewModel.currentState.iconName)
            .font(.system(size: DesignSystem.FontSize.extraLarge))
            .foregroundColor(viewModel.currentState.backgroundColor)
        
        Text(viewModel.currentState.displayName)
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)
        
        if viewModel.isLoading {
            ProgressView()
                .scaleEffect(0.8)
        }
        
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
        }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(DesignSystem.CornerRadius.card)
}
```

### Mode Buttons Grid

2x2 grid layout for alarm mode controls:

```swift
private var modeButtonsSection: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.buttonSpacing) {
        ModeButton(
            mode: .away,
            isEnabled: viewModel.canChangeMode,
            action: { viewModel.requestModeChange(.away) }
        )
        
        ModeButton(
            mode: .stay,
            isEnabled: viewModel.canChangeMode,
            action: { viewModel.requestModeChange(.stay) }
        )
        
        ModeButton(
            mode: .nightStay,
            isEnabled: viewModel.canChangeMode,
            action: { viewModel.requestModeChange(.nightStay) }
        )
        
        ModeButton(
            mode: .disarm,
            isEnabled: viewModel.canChangeMode,
            action: { viewModel.requestModeChange(.disarm) }
        )
    }
    .padding()
}
```

### PIN Display

Visual feedback for PIN entry progress:

```swift
private var pinDisplaySection: some View {
    HStack(spacing: DesignSystem.Spacing.buttonSpacing) {
        ForEach(0..<6, id: \.self) { index in
            Circle()
                .fill(index < enteredPIN.count ? Color.primary : Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
        }
    }
    .padding()
}
```

### Keypad Interface

Phone-style numeric keypad:

```swift
private var keypadSection: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignSystem.Spacing.buttonSpacing) {
        ForEach(1...9, id: \.self) { number in
            KeypadButton(
                number: number,
                isEnabled: !viewModel.lockoutService.isLockedOut(),
                action: { addDigit(number) }
            )
        }
        
        // Bottom row: *, 0, #
        KeypadButton(number: 0, isEnabled: !viewModel.lockoutService.isLockedOut(), action: { addDigit(0) })
        
        Button("Delete") {
            deleteDigit()
        }
        .disabled(enteredPIN.isEmpty)
        
        Button("Submit") {
            submitPIN()
        }
        .disabled(enteredPIN.count != 6)
    }
    .padding()
}
```

## 🎨 Design System Integration

### Color Coding

Consistent color scheme across all components:

```swift
extension AlarmMode {
    var buttonColor: Color {
        switch self {
        case .away: return .red
        case .stay: return .orange
        case .nightStay: return .purple
        case .disarm: return .green
        }
    }
}
```

### Typography

Semantic font usage:

```swift
private var stateTitle: some View {
    Text(viewModel.currentState.displayName)
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.primary)
}
```

### Spacing

Consistent spacing using design system:

```swift
VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
    // Content
}
.padding(DesignSystem.Spacing.cardPadding)
```

## 🔄 State Management

### Reactive Updates

Views automatically update based on ViewModel state:

```swift
@ObservedObject var viewModel: AlarmViewModel

var body: some View {
    // UI automatically updates when viewModel properties change
    if viewModel.isLoading {
        ProgressView()
    } else {
        stateDisplay
    }
}
```

### User Interactions

Handle user input and trigger ViewModel actions:

```swift
Button("Away") {
    viewModel.requestModeChange(.away)
}
.disabled(!viewModel.canChangeMode)
```

## 🧪 Testing

### UI Testing

Test user interactions and visual feedback:

```swift
func testAlarmModeButton() {
    let app = XCUIApplication()
    app.launch()
    
    let awayButton = app.buttons["Away"]
    XCTAssertTrue(awayButton.exists)
    XCTAssertTrue(awayButton.isEnabled)
    
    awayButton.tap()
    XCTAssertTrue(app.sheets["PIN Entry"].exists)
}

func testPINEntry() {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons["Away"].tap()
    
    // Enter PIN
    app.buttons["1"].tap()
    app.buttons["2"].tap()
    app.buttons["3"].tap()
    app.buttons["4"].tap()
    app.buttons["5"].tap()
    app.buttons["6"].tap()
    
    // Submit
    app.buttons["Submit"].tap()
    
    // Verify state change
    XCTAssertTrue(app.staticTexts["Armed Away"].exists)
}
```

### Accessibility Testing

Test accessibility features:

```swift
func testAccessibility() {
    let app = XCUIApplication()
    app.launch()
    
    // Test VoiceOver support
    let awayButton = app.buttons["Away"]
    XCTAssertTrue(awayButton.isAccessibilityElement)
    XCTAssertEqual(awayButton.label, "Away")
    
    // Test accessibility hints
    XCTAssertTrue(awayButton.accessibilityHint.contains("Tap to set alarm to away mode"))
}
```

## 🚀 Performance

### Optimization Strategies

- **LazyVGrid**: Efficient grid rendering for mode buttons
- **State Caching**: Minimize unnecessary view updates
- **Image Caching**: Reuse SF Symbol images
- **Memory Management**: Proper view lifecycle management

### Responsive Design

Adapt to different screen sizes:

```swift
private var modeButtonsSection: some View {
    LazyVGrid(
        columns: Array(repeating: GridItem(.flexible()), count: gridColumns),
        spacing: DesignSystem.Spacing.buttonSpacing
    ) {
        // Mode buttons
    }
}

private var gridColumns: Int {
    UIDevice.current.userInterfaceIdiom == .pad ? 2 : 2
}
```

## 📁 Files

- **AlarmTabView.swift** - Main alarm interface
- **PINEntryView.swift** - Secure PIN entry modal
- **ModeButton.swift** - Individual mode button component

## 🔗 Navigation

- **[Alarm System](../README.md)** - Main alarm system documentation
- **[Models](../Models/README.md)** - Alarm data models
- **[Services](../Services/README.md)** - Alarm services and business logic
- **[ViewModels](../ViewModels/README.md)** - UI state management

---

These SwiftUI views provide an intuitive, secure, and responsive user interface for the alarm system's core functionality.
