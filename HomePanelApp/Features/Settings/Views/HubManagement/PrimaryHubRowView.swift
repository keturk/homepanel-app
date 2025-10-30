import SwiftUI

struct PrimaryHubRowView: View {
    let configuration: HubConfiguration
    let isSelected: Bool
    let onSelect: (HubConfiguration) -> Void
    
    var body: some View {
        HStack {
            // Primary Hub Indicator
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(configuration.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if configuration.isEnabled {
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Text("Offline")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Text(configuration.hubType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Handles alarm operations and scenes")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .italic()
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}
