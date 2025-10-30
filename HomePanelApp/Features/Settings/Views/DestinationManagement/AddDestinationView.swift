import SwiftUI

// MARK: - Add Destination View

struct AddDestinationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var destinationStore: DestinationStore

    @State private var name: String = ""
    @State private var address: String = ""
    @State private var isGeocoding = false
    @State private var errorMessage: String?

    private let geocodingService = GeocodingService()

    var body: some View {
        NavigationView {
            Form {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                    // Name Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("Destination Name")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        TextField("e.g., Work, Home, Gym", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }

                    // Address Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                        Text("Address")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        TextField("e.g., 1 Apple Park Way, Cupertino, CA", text: $address)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            .autocapitalization(.words)

                        Text("Enter a full address including city and state")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Error Message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Save Button
                    Button(action: {
                        Task {
                            await saveDestination()
                        }
                    }) {
                        if isGeocoding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Add Destination")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSave ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(!canSave || isGeocoding)
                }
                .padding()
            }
            .navigationTitle("Add Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func saveDestination() async {
        errorMessage = nil
        isGeocoding = true

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)

        do {
            // Geocode address
            let (latitude, longitude, formattedAddress) = try await geocodingService.geocodeAddress(trimmedAddress)

            // Create destination
            let destination = FavoriteDestination(
                name: trimmedName,
                address: formattedAddress,
                latitude: latitude,
                longitude: longitude,
                isEnabled: true
            )

            // Save to store
            try await destinationStore.addDestination(destination)

            DebugLogger.log("✅ [AddDestinationView] Added destination: \(trimmedName)", feature: .settings)
            HapticFeedback.success()

            dismiss()
        } catch {
            DebugLogger.error("❌ [AddDestinationView] Failed to add destination: \(error)", feature: .settings)
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }

        isGeocoding = false
    }
}

// MARK: - Preview

#Preview {
    let store = DependencyContainer.shared.getDestinationStore()

    AddDestinationView(destinationStore: store)
}
