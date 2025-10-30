import SwiftUI
import Combine

// MARK: - Keyboard Avoidance Modifier

/// A view modifier that automatically adjusts ScrollView content to avoid being covered by the keyboard
/// This is especially useful on iPad where the keyboard can cover input fields
/// IMPORTANT: Only use this on ScrollView content, not on the view hierarchy that contains Forms or TextEditors
struct KeyboardAvoidanceModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible: Bool = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                // Use safeAreaInset instead of padding to avoid layout issues
                Color.clear
                    .frame(height: isKeyboardVisible ? keyboardHeight : 0)
            }
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                    isKeyboardVisible = height > 0
                }
            }
    }
}

// MARK: - Keyboard Height Publisher

extension Publishers {
    /// Publisher that emits keyboard height changes
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - Keyboard Responsive Scroll View

/// A ScrollView that automatically scrolls to keep the active text field visible when keyboard appears
struct KeyboardResponsiveScrollView<Content: View>: View {
    let content: Content

    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                content
                    .padding(.bottom, max(keyboardHeight - geometry.safeAreaInsets.bottom, 0))
            }
            .onReceive(Publishers.keyboardHeight) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds keyboard avoidance behavior to automatically adjust content when keyboard appears
    /// This prevents the keyboard from covering text fields and other input elements
    func keyboardAware() -> some View {
        modifier(KeyboardAvoidanceModifier())
    }

    /// Wraps content in a keyboard-responsive scroll view
    /// Use this for forms and dialogs with text input fields
    func keyboardResponsiveScrollView() -> some View {
        KeyboardResponsiveScrollView {
            self
        }
    }
}

// MARK: - Keyboard State Monitor

/// Observable object that tracks keyboard state globally
@MainActor
class KeyboardStateMonitor: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var height: CGFloat = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Monitor keyboard show events
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height
            }
            .sink { [weak self] height in
                self?.isVisible = true
                self?.height = height
            }
            .store(in: &cancellables)

        // Monitor keyboard hide events
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.isVisible = false
                self?.height = 0
            }
            .store(in: &cancellables)
    }
}

// MARK: - Preview

#Preview("Keyboard Avoidance Test") {
    VStack(spacing: 20) {
        Text("Keyboard Avoidance Example")
            .font(.headline)

        TextField("Test Field 1", text: .constant(""))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

        TextField("Test Field 2", text: .constant(""))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

        TextField("Test Field 3", text: .constant(""))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

        Spacer()
    }
    .keyboardAware()
}
