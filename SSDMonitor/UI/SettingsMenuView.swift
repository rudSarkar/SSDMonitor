import SwiftUI

struct SettingsMenuView: View {
    @ObservedObject var settings: UserSettings

    var body: some View {
        HStack(spacing: 12) {
            Picker("Interval", selection: $settings.refreshInterval) {
                ForEach(UserSettings.validIntervals, id: \.self) { interval in
                    Text(intervalLabel(interval)).tag(interval)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
            .labelsHidden()

            Picker("Unit", selection: $settings.unit) {
                ForEach(TemperatureUnit.allCases) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 88)
            .labelsHidden()

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit", systemImage: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private func intervalLabel(_ seconds: Double) -> String {
        if seconds < 1 { return "\(Int(seconds * 1000))ms" }
        return seconds == seconds.rounded() ? "\(Int(seconds))s" : "\(seconds)s"
    }
}
