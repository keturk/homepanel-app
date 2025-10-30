import SwiftUI

// MARK: - PIN Row View

struct PINRowView: View {
    let pinData: PINData
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.rowSpacing) {
                Text(pinData.name.isEmpty ? "Unnamed PIN" : pinData.name)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                
                if let lastUsed = pinData.lastUsed {
                    Text("Last used: \(lastUsed, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never used")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Delete") {
                showDeleteAlert = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .foregroundColor(.white)
            .background(Color.red)
            .cornerRadius(8)
            .accessibilityLabel("Delete \(pinData.name.isEmpty ? "Unnamed PIN" : pinData.name)")
            .accessibilityHint("Tap to delete this PIN")
            .accessibilityAddTraits(.isButton)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(DesignSystem.CornerRadius.pinRow)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("PIN entry for \(pinData.name.isEmpty ? "Unnamed PIN" : pinData.name)")
        .accessibilityHint("PIN entry with last used information")
        .alert("Delete PIN", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this PIN? This action cannot be undone.")
        }
    }
}
