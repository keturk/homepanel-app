import SwiftUI

// MARK: - Keyboard Toolbar Component

struct KeyboardToolbar: ToolbarContent {
    let onDone: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            
            Button("Done") {
                onDone()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
            .accessibilityLabel("Done")
            .accessibilityHint("Tap to dismiss the keyboard")
            .accessibilityAddTraits(.isButton)
        }
    }
}

// MARK: - Keyboard Toolbar Modifier

struct KeyboardToolbarModifier: ViewModifier {
    let onDone: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                KeyboardToolbar(onDone: onDone)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a keyboard toolbar with Done button
    func keyboardToolbar(onDone: @escaping () -> Void = {}) -> some View {
        modifier(KeyboardToolbarModifier(onDone: onDone))
    }
}

// MARK: - Tap Outside to Dismiss Modifier

struct TapOutsideToDismissModifier: ViewModifier {
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onTapGesture {
                if isFocused {
                    isFocused = false
                }
            }
    }
}

// MARK: - View Extension for Tap Outside

extension View {
    /// Adds tap-outside-to-dismiss functionality for keyboard
    func tapOutsideToDismiss() -> some View {
        modifier(TapOutsideToDismissModifier())
    }
}

// MARK: - Combined Keyboard Handling Modifier

struct KeyboardHandlingModifier: ViewModifier {
    let onDone: () -> Void
    
    func body(content: Content) -> some View {
        content
            .keyboardToolbar(onDone: onDone)
            .tapOutsideToDismiss()
    }
}

// MARK: - View Extension for Combined Keyboard Handling

extension View {
    /// Adds both keyboard toolbar and tap-outside-to-dismiss functionality
    func keyboardHandling(onDone: @escaping () -> Void = {}) -> some View {
        modifier(KeyboardHandlingModifier(onDone: onDone))
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        VStack(spacing: 20) {
            TextField("Test Field 1", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardHandling()
            
            TextField("Test Field 2", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardHandling()
            
            TextEditor(text: .constant("Test text editor"))
                .frame(height: 100)
                .keyboardHandling()
        }
        .padding()
        .navigationTitle("Keyboard Toolbar Test")
    }
}
