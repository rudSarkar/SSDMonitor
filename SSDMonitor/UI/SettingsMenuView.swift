import SwiftUI

struct SettingsMenuView: View {
    @ObservedObject var settings: UserSettings
    @ObservedObject var updater:  UpdateChecker

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: refresh interval + temperature unit + quit
            HStack(spacing: 10) {
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
                .frame(width: 66)
                .labelsHidden()

                Spacer()

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Label("Quit", systemImage: "power")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            // Row 2: launch at login + update status
            HStack {
                Toggle(isOn: $settings.launchAtLogin) {
                    Text("Launch at Login")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.checkbox)

                Spacer()

                updateStatusView
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var updateStatusView: some View {
        if let version = updater.availableVersion, let url = updater.releasePageURL {
            Link(destination: url) {
                Label("Update \(version) available", systemImage: "arrow.down.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        } else if updater.isChecking {
            Label("Checking…", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else {
            Button(action: { updater.checkForUpdates() }) {
                Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func intervalLabel(_ seconds: Double) -> String {
        if seconds < 1 { return "\(Int(seconds * 1000))ms" }
        return seconds == seconds.rounded() ? "\(Int(seconds))s" : "\(seconds)s"
    }
}
