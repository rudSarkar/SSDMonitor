import Foundation
import Combine

@MainActor
final class MonitorService: ObservableObject {

    @Published var stats   = SSDStats()
    @Published var settings: UserSettings

    private let tempReader: TemperatureReader
    private let diskReader = DiskIOReader()
    private var timer:       AnyCancellable?
    private var intervalCancellable: AnyCancellable?

    init(settings: UserSettings) {
        self.settings = settings
        self.tempReader = MonitorService.makeTemperatureReader()
    }

    private static func makeTemperatureReader() -> TemperatureReader {
        #if arch(arm64)
        return HIDTemperatureReader()
        #else
        return SMCTemperatureReader()
        #endif
    }

    func start() {
        // Prime the disk reader so the first real delta is meaningful
        _ = diskReader.readSpeedsMBs()

        startTimer()

        // Restart the timer whenever the refresh interval changes
        intervalCancellable = settings.$refreshInterval
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.restart() }
    }

    private func startTimer() {
        timer = Timer.publish(every: settings.refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    func restart() {
        timer = nil
        startTimer()
    }

    func stop() {
        timer = nil
        intervalCancellable = nil
    }

    private func refresh() {
        let temp              = tempReader.readTemperatureCelsius()
        let (readMBs, writeMBs) = diskReader.readSpeedsMBs()
        #if DEBUG
        print("[SSDMonitor] temp=\(temp.map { String(format: "%.1f°C", $0) } ?? "--") R=\(String(format: "%.2f", readMBs)) W=\(String(format: "%.2f", writeMBs)) MB/s disk=\(diskReader.diskName)")
        #endif
        stats = SSDStats(
            temperatureCelsius: temp,
            readSpeedMBs:  readMBs,
            writeSpeedMBs: writeMBs,
            diskName:      diskReader.diskName,
            timestamp:     Date()
        )
    }
}
