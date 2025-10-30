import SwiftUI

// MARK: - Scrollable Form View

struct ScrollableFormView<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    let onKeyboardShow: (() -> Void)?
    
    init(
        title: String,
        subtitle: String? = nil,
        onKeyboardShow: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onKeyboardShow = onKeyboardShow
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.large) {
                // Header section with title
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                content
            }
            .padding(.top, DesignSystem.Spacing.large)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
        .background(Color(.systemGroupedBackground))
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            onKeyboardShow?()
        }
    }
}

// MARK: - Scrollable Form Section

struct ScrollableFormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding(DesignSystem.Spacing.medium)
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Form Field

struct FormField<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            content
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollableFormView(
        title: "Test Form",
        subtitle: "This is a test form"
    ) {
        ScrollableFormSection(title: "Test Section") {
            VStack(spacing: DesignSystem.Spacing.medium) {
                FormField(label: "Test Field") {
                    TextField("Enter text", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                FormField(label: "Another Field") {
                    TextField("Enter more text", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
}
