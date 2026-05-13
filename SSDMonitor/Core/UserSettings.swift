import Foundation
import Combine

final class UserSettings: ObservableObject {
    @Published var unit: TemperatureUnit {
        didSet { UserDefaults.standard.set(unit.rawValue, forKey: Keys.unit) }
    }

    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: Keys.interval) }
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
    }
}
