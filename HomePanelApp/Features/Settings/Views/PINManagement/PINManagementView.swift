import SwiftUI

// MARK: - PIN Management View

struct PINManagementView: View {
    @ObservedObject var pinService: PINManagementService
    @State private var showMasterPINEntry = false
    @State private var showAddPIN = false
    @State private var showChangeMasterPIN = false
    @State private var errorMessage: String?
    @State private var toastMessage: ToastMessage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
                if pinService.masterPINData == nil {
                    // Initial setup - set master PIN
                    initialSetupView
                } else {
                    // PIN management interface
                    pinManagementView
                }
            }
            .overlay(
                ToastBannerOverlay(toastMessage: $toastMessage)
            )
        .sheet(isPresented: $showMasterPINEntry) {
            MasterPINEntryView(
                onVerify: { pin in
                    if pinService.setMasterPIN(pin) {
                        showMasterPINEntry = false
                        errorMessage = nil
                        toastMessage = ToastMessage(title: "Master PIN set successfully", type: .success)
                        HapticFeedback.success()
                    } else {
                        errorMessage = pinService.errorMessage ?? "Invalid PIN"
                        toastMessage = ToastMessage(title: "Failed to set Master PIN", message: pinService.errorMessage, type: .error)
                        HapticFeedback.error()
                    }
                },
                onCancel: {
                    showMasterPINEntry = false
                    pinService.clearError()
                    dismiss()
                },
                pinService: pinService
            )
            // Master PIN entry should allow dismissal (authentication, not data entry)
        }
        .sheet(isPresented: $showAddPIN) {
            AddPINView(
                onAdd: { pin, name in
                    if pinService.addUserPIN(pin, name: name) {
                        showAddPIN = false
                        errorMessage = nil
                        toastMessage = ToastMessage(title: "PIN added successfully", message: "User PIN for \(name) has been added", type: .success)
                        HapticFeedback.success()
                    } else {
                        errorMessage = pinService.errorMessage ?? "Failed to add PIN. Name may already be taken or PIN is invalid."
                        toastMessage = ToastMessage(title: "Failed to add PIN", message: pinService.errorMessage, type: .error)
                        HapticFeedback.error()
                    }
                },
                onCancel: {
                    showAddPIN = false
                    pinService.clearError()
                },
                isUsernameAvailable: { username in
                    let trimmedName = username.trimmingCharacters(in: .whitespacesAndNewlines)
                    return !pinService.userPINs.contains(where: { $0.name == trimmedName })
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChangeMasterPIN) {
            ChangeMasterPINView(
                pinService: pinService,
                onChange: { oldPIN, newPIN in
                    if pinService.changeMasterPIN(oldPIN: oldPIN, newPIN: newPIN) {
                        showChangeMasterPIN = false
                        errorMessage = nil
                        toastMessage = ToastMessage(title: "Master PIN changed successfully", type: .success)
                        HapticFeedback.success()
                    } else {
                        errorMessage = pinService.errorMessage ?? "Failed to change master PIN. Check your current PIN."
                        toastMessage = ToastMessage(title: "Failed to change Master PIN", message: pinService.errorMessage, type: .error)
                        HapticFeedback.error()
                    }
                },
                onCancel: {
                    showChangeMasterPIN = false
                    pinService.clearError()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(true) // Prevent accidental data loss
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force full-screen on iPad
    }
    
    // MARK: - Initial Setup View
    
    private var initialSetupView: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Set Up Master PIN")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Create a master PIN to manage all other PINs. This PIN will be required to add, remove, or modify user PINs.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Set Master PIN") {
                showMasterPINEntry = true
            }
            .buttonStyle(.primary())
            .accessibilityLabel("Set Master PIN")
            .accessibilityHint("Tap to create a master PIN for managing all other PINs")
            .accessibilityAddTraits(.isButton)
        }
        .padding()
    }
    
    // MARK: - PIN Management View
    
    private var pinManagementView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Master PIN section
                masterPINSection
                
                // Add New User PIN Button - Between Master PIN and User PINs
                Button(action: { 
                    DebugLogger.log("🔍 [PINManagementView] Add PIN button tapped", feature: .settings)
                    showAddPIN = true
                    HapticFeedback.buttonPress()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        Text("Add New User PIN")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add New User PIN")
                .accessibilityHint("Tap to add a new user PIN")
                
                Divider()
                
                // User PINs section
                userPINsSection
                
                // Add bottom padding to ensure last item is fully visible
                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
    }
    
    private var masterPINSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Master PIN")
                    .font(.headline)
                Spacer()
                Button("Change") {
                    if pinService.isLockedOut() {
                        errorMessage = "Master PIN change is locked. Try again in \(pinService.getRemainingLockoutTime())"
                        toastMessage = ToastMessage(title: "Master PIN change locked", message: "Try again in \(pinService.getRemainingLockoutTime())", type: .warning)
                        HapticFeedback.warning()
                    } else {
                        showChangeMasterPIN = true
                        HapticFeedback.buttonPress()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(pinService.isLockedOut())
                .accessibilityLabel("Change Master PIN")
                .accessibilityHint("Tap to change the master PIN")
                .accessibilityAddTraits(.isButton)
            }
            
            if let lastUsed = pinService.masterPINLastUsed {
                Text("Last used: \(formatLastUsed(lastUsed))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Never used")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var userPINsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("User PINs")
                .font(.headline)
            
            if pinService.userPINs.isEmpty {
                Text("No user PINs added yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(pinService.userPINs) { pinData in
                        PINRowView(pinData: pinData) {
                            if pinService.removeUserPIN(pinData.id) {
                                toastMessage = ToastMessage(title: "PIN removed successfully", message: "User PIN for \(pinData.name) has been removed", type: .success)
                                HapticFeedback.success()
                            } else {
                                toastMessage = ToastMessage(title: "Failed to remove PIN", message: "Could not remove PIN for \(pinData.name)", type: .error)
                                HapticFeedback.error()
                            }
                        }
                    }
                }
                .padding(.bottom, 20) // Extra padding for the last item
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func formatLastUsed(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


// MARK: - Preview

#Preview {
    PINManagementView(pinService: DependencyContainer.shared.getPINManagementService() as! PINManagementService)
}
