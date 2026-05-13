import Foundation

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius    = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .celsius:    return "°C"
        case .fahrenheit: return "°F"
        }
    }
}

struct SSDStats {
    var temperatureCelsius: Double?
    var readSpeedMBs: Double  = 0
    var writeSpeedMBs: Double = 0
    var diskName: String      = "—"
    var timestamp: Date       = Date()

    func temperature(in unit: TemperatureUnit) -> Double? {
        guard let c = temperatureCelsius else { return nil }
        return unit == .celsius ? c : c * 9 / 5 + 32
    }

    func formattedTemperature(in unit: TemperatureUnit) -> String {
        guard let t = temperature(in: unit) else { return "--\(unit.symbol)" }
        return String(format: "%.0f%@", t, unit.symbol)
    }

    func formattedSpeed(_ mbs: Double) -> String {
        if mbs >= 1000 { return String(format: "%.1f GB/s", mbs / 1000) }
        if mbs >= 1    { return String(format: "%.1f MB/s", mbs) }
        return String(format: "%.0f KB/s", mbs * 1024)
    }
}
