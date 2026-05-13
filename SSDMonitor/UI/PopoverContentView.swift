import SwiftUI

struct PopoverContentView: View {
    @ObservedObject var monitor: MonitorService

    // Reference speed for normalising bars (500 MB/s = fast NVMe baseline)
    private let barMax: Double = 500

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            temperatureSection
            Divider().padding(.horizontal, 16)
            speedSection
            Divider()
            diskInfoRow
            Divider()
            settingsRow
        }
        .frame(width: 280)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            Image(systemName: "internaldrive.fill")
                .foregroundStyle(.blue)
            Text("SSD Monitor")
                .font(.headline)
            Text("v\(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.leading, 2)
            Spacer()
            Circle()
                .fill(.green)
                .frame(width: 7, height: 7)
                .help("Live — updates every \(Int(monitor.settings.refreshInterval))s")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var temperatureSection: some View {
        HStack {
            Spacer()
            TemperatureGaugeView(stats: monitor.stats, unit: monitor.settings.unit)
            Spacer()
        }
        .padding(.vertical, 14)
    }

    private var speedSection: some View {
        VStack(spacing: 10) {
            SpeedRowView(
                label:    "Read",
                icon:     "arrow.down.circle.fill",
                speed:    monitor.stats.readSpeedMBs,
                maxSpeed: barMax,
                color:    .blue
            )
            SpeedRowView(
                label:    "Write",
                icon:     "arrow.up.circle.fill",
                speed:    monitor.stats.writeSpeedMBs,
                maxSpeed: barMax,
                color:    .orange
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var diskInfoRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Text(monitor.stats.diskName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var settingsRow: some View {
        SettingsMenuView(settings: monitor.settings, updater: monitor.updateChecker)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }
}
