import SwiftUI

struct DeviceStatusIndicator: View {
    enum Status {
        case executing
        case placeholder
        case disconnected
        case normal(String) // "Tap to activate" or empty
    }
    
    let status: Status
    
    var body: some View {
        HStack {
            content
            Spacer()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch status {
        case .executing:
            HStack(spacing: 4) {
                ProgressView().scaleEffect(0.8).tint(.white)
                Text("Executing...").font(.system(size: 12, weight: .medium))
            }
        case .placeholder:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle").font(.system(size: 10))
                Text("Not available").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.orange)
        case .disconnected:
            HStack(spacing: 4) {
                Image(systemName: "wifi.slash").font(.system(size: 10))
                Text("Disconnected").font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.red)
        case .normal(let text):
            if !text.isEmpty {
                Text(text).font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}
