import SwiftUI

struct SpeedRowView: View {
    let label:    String
    let icon:     String
    let speed:    Double        // MB/s
    let maxSpeed: Double        // normalises the bar
    let color:    Color

    private var fraction: Double {
        guard maxSpeed > 0 else { return 0 }
        return min(1, speed / maxSpeed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formattedSpeed)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.gradient)
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 6)
        }
    }

    private var formattedSpeed: String {
        if speed >= 1000 { return String(format: "%.1f GB/s", speed / 1000) }
        if speed >= 1    { return String(format: "%.1f MB/s", speed) }
        return String(format: "%.0f KB/s", speed * 1024)
    }
}
