import SwiftUI

// MARK: - Edit Destination View

struct EditDestinationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var destinationStore: DestinationStore

    let destination: FavoriteDestination

    @State private var name: String
    @State private var address: String
    @State private var isEnabled: Bool
    @State private var isGeocoding = false
    @State private var errorMessage: String?

    private let geocodingService = GeocodingService()

    init(destination: FavoriteDestination, destinationStore: DestinationStore) {
        self.destination = destination
        self.destinationStore = destinationStore
        _name = State(initialValue: destination.name)
        _address = State(initialValue: destination.address)
        _isEnabled = State(initialValue: destination.isEnabled)
    }

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

                    // Enabled Toggle
                    Toggle(isOn: $isEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show in Traffic View")
                                .font(.headline)
                            Text("Display travel time to this destination")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                            Text("Save Changes")
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
            .navigationTitle("Edit Destination")
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
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        hasChanges
    }

    private var hasChanges: Bool {
        name != destination.name ||
        address != destination.address ||
        isEnabled != destination.isEnabled
    }

    // MARK: - Actions

    private func saveDestination() async {
        errorMessage = nil
        isGeocoding = true

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedAddress = address.trimmingCharacters(in: .whitespaces)

        do {
            var latitude = destination.latitude
            var longitude = destination.longitude
            var formattedAddress = trimmedAddress

            // Only re-geocode if address changed
            if trimmedAddress != destination.address {
                let result = try await geocodingService.geocodeAddress(trimmedAddress)
                latitude = result.latitude
                longitude = result.longitude
                formattedAddress = result.formattedAddress
            }

            // Create updated destination
            let updatedDestination = FavoriteDestination(
                id: destination.id,
                name: trimmedName,
                address: formattedAddress,
                latitude: latitude,
                longitude: longitude,
                isEnabled: isEnabled
            )

            // Update in store
            try await destinationStore.updateDestination(updatedDestination)

            DebugLogger.log("✅ [EditDestinationView] Updated destination: \(trimmedName)", feature: .settings)
            HapticFeedback.success()

            dismiss()
        } catch {
            DebugLogger.error("❌ [EditDestinationView] Failed to update destination: \(error)", feature: .settings)
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }

        isGeocoding = false
    }
}

// MARK: - Preview

#Preview {
    let store = DependencyContainer.shared.getDestinationStore()
    let destination = FavoriteDestination.samples[0]

    EditDestinationView(destination: destination, destinationStore: store)
}
