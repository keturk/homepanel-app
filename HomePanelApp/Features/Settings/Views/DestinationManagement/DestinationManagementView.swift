import SwiftUI

// MARK: - Destination Management View

struct DestinationManagementView: View {
    @ObservedObject var destinationStore: DestinationStore
    @State private var showingAddDestination = false
    @State private var destinationToEdit: FavoriteDestination?
    @State private var destinationToDelete: FavoriteDestination?
    @State private var showingDeleteAlert = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        let _ = DebugLogger.log("🏠 [DestinationManagementView] Rendering with \(destinationStore.destinations.count) destinations", feature: .settings)

        return ScrollView {
            VStack(spacing: 20) {
                // Add New Destination Button
                Button(action: {
                    DebugLogger.log("➕ [DestinationManagementView] Add button tapped", feature: .settings)
                    showingAddDestination = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Add New Destination")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .accessibilityLabel("Add New Destination")
                .accessibilityHint("Tap to add a new favorite destination")

                if destinationStore.destinations.isEmpty {
                    emptyStateSection
                } else {
                    destinationsSection
                }
            }
            .padding(.top, 20)
        }
        .navigationTitle("Favorite Destinations")
        .sheet(isPresented: $showingAddDestination) {
            AddDestinationView(destinationStore: destinationStore)
        }
        .sheet(item: $destinationToEdit) { destination in
            EditDestinationView(destination: destination, destinationStore: destinationStore)
        }
        .alert("Delete Destination", isPresented: $showingDeleteAlert, presenting: destinationToDelete) { destination in
            Button("Cancel", role: .cancel) {
                destinationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteDestination(destination)
                }
            }
        } message: { destination in
            Text("Are you sure you want to delete \"\(destination.name)\"?")
        }
        .task {
            await loadDestinations()
        }
    }

    // MARK: - Empty State Section

    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Destinations")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add favorite destinations to see traffic information on the alarm screen. Traffic updates every 5 minutes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }

    // MARK: - Destinations Section

    private var destinationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Destinations (\(destinationStore.destinations.count))")
                .font(.headline)
                .padding(.horizontal, 20)

            ForEach(Array(destinationStore.destinations.enumerated()), id: \.element.id) { index, destination in
                DestinationCard(
                    destination: destination,
                    destinationStore: destinationStore,
                    index: index,
                    totalCount: destinationStore.destinations.count,
                    onEdit: {
                        destinationToEdit = destination
                    },
                    onDelete: {
                        destinationToDelete = destination
                        showingDeleteAlert = true
                    },
                    onMoveUp: {
                        moveDestinationUp(at: index)
                    },
                    onMoveDown: {
                        moveDestinationDown(at: index)
                    }
                )
                .padding(.horizontal, 20)
            }

            Text("Tap row to edit destination. Enabled destinations show travel time on the alarm screen. Traffic updates every 5 minutes.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func loadDestinations() async {
        do {
            let _ = try await destinationStore.loadDestinations()
            DebugLogger.log("✅ [DestinationManagementView] Loaded destinations", feature: .settings)
        } catch {
            DebugLogger.error("❌ [DestinationManagementView] Failed to load destinations: \(error)", feature: .settings)
        }
    }

    private func moveDestinationUp(at index: Int) {
        guard index > 0 else { return }

        Task {
            var updatedDestinations = destinationStore.destinations
            updatedDestinations.swapAt(index, index - 1)

            do {
                try await destinationStore.saveDestinations(updatedDestinations)
                DebugLogger.log("✅ [DestinationManagementView] Moved destination up", feature: .settings)
                HapticFeedback.selection()
            } catch {
                DebugLogger.error("❌ [DestinationManagementView] Failed to move destination: \(error)", feature: .settings)
                HapticFeedback.error()
            }
        }
    }

    private func moveDestinationDown(at index: Int) {
        guard index < destinationStore.destinations.count - 1 else { return }

        Task {
            var updatedDestinations = destinationStore.destinations
            updatedDestinations.swapAt(index, index + 1)

            do {
                try await destinationStore.saveDestinations(updatedDestinations)
                DebugLogger.log("✅ [DestinationManagementView] Moved destination down", feature: .settings)
                HapticFeedback.selection()
            } catch {
                DebugLogger.error("❌ [DestinationManagementView] Failed to move destination: \(error)", feature: .settings)
                HapticFeedback.error()
            }
        }
    }

    private func deleteDestination(_ destination: FavoriteDestination) async {
        do {
            try await destinationStore.deleteDestination(id: destination.id)
            DebugLogger.log("✅ [DestinationManagementView] Deleted destination: \(destination.name)", feature: .settings)
            HapticFeedback.success()
        } catch {
            DebugLogger.error("❌ [DestinationManagementView] Failed to delete destination: \(error)", feature: .settings)
            HapticFeedback.error()
        }
        destinationToDelete = nil
    }
}

// MARK: - Destination Card

struct DestinationCard: View {
    let destination: FavoriteDestination
    @ObservedObject var destinationStore: DestinationStore
    let index: Int
    let totalCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 12) {
                // Reorder Buttons
                VStack(spacing: 4) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(index == 0 ? .gray.opacity(0.3) : .blue)
                    }
                    .disabled(index == 0)

                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(index == totalCount - 1 ? .gray.opacity(0.3) : .blue)
                    }
                    .disabled(index == totalCount - 1)
                }
                .frame(width: 24)

                // Icon
                Image(systemName: destination.isEnabled ? "location.fill" : "location")
                    .font(.title2)
                    .foregroundColor(destination.isEnabled ? .blue : .gray)
                    .frame(width: 30)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(destination.name)
                        .font(.headline)

                    Text(destination.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Toggle
                Toggle("", isOn: Binding(
                    get: { destination.isEnabled },
                    set: { newValue in
                        Task {
                            await toggleDestination(newValue)
                        }
                    }
                ))
                .labelsHidden()
            }
            .padding(16)

            // Action Buttons
            Divider()

            HStack(spacing: 0) {
                // Edit Button
                Button(action: onEdit) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Divider()

                // Delete Button
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func toggleDestination(_ isEnabled: Bool) async {
        let updated = FavoriteDestination(
            id: destination.id,
            name: destination.name,
            address: destination.address,
            latitude: destination.latitude,
            longitude: destination.longitude,
            isEnabled: isEnabled
        )

        do {
            try await destinationStore.updateDestination(updated)
            DebugLogger.log("✅ [DestinationCard] Toggled destination: \(destination.name) -> \(isEnabled)", feature: .settings)
            HapticFeedback.selection()
        } catch {
            DebugLogger.error("❌ [DestinationCard] Failed to toggle destination: \(error)", feature: .settings)
            HapticFeedback.error()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        let store = DependencyContainer.shared.getDestinationStore()

        DestinationManagementView(destinationStore: store)
    }
}
