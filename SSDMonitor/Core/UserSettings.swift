import Foundation
import Combine
import ServiceManagement

final class UserSettings: ObservableObject {
    @Published var unit: TemperatureUnit {
        didSet { UserDefaults.standard.set(unit.rawValue, forKey: Keys.unit) }
    }

    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: Keys.interval) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[SSDMonitor] Launch at login: \(error.localizedDescription)")
            }
        }
    }

    static let validIntervals: [Double] = [1, 2, 5, 10]

    private enum Keys {
        static let unit     = "temperatureUnit"
        static let interval = "refreshInterval"
    }

    init() {
        let raw  = UserDefaults.standard.string(forKey: Keys.unit) ?? ""
        unit = TemperatureUnit(rawValue: raw) ?? .celsius

        let stored = UserDefaults.standard.double(forKey: Keys.interval)
        refreshInterval = UserSettings.validIntervals.contains(stored) ? stored : 2

        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
