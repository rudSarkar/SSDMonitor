import Foundation

/// Common interface for all temperature reader backends.
protocol TemperatureReader {
    func readTemperatureCelsius() -> Double?
}
