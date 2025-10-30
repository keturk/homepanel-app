import SwiftUI

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: DesignSystem.FrameSize.iconFrame)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignSystem.Spacing.buttonSpacing) {
        FeatureRow(icon: "video.circle.fill", title: "Live Video Streaming")
        FeatureRow(icon: "record.circle.fill", title: "Recording Controls")
        FeatureRow(icon: "grid.circle.fill", title: "Multi-Camera Grid")
        FeatureRow(icon: "play.circle.fill", title: "Playback History")
    }
    .padding()
}
