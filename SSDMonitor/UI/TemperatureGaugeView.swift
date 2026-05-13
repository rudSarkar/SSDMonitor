import SwiftUI

struct TemperatureGaugeView: View {
    let stats:    SSDStats
    let unit:     TemperatureUnit

    private var celsius: Double? { stats.temperatureCelsius }
    private var fraction: Double {
        guard let c = celsius else { return 0 }
        return max(0, min(1, (c - 20) / 80))   // 20°C → 0%, 100°C → 100%
    }

    private var gaugeColor: Color {
        switch fraction {
        case ..<0.4: return .green
        case ..<0.7: return .yellow
        default:     return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 8)

                if celsius != nil {
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.green, .yellow, .red]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: fraction)
                }

                VStack(spacing: 2) {
                    Text(stats.formattedTemperature(in: unit))
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(celsius != nil ? gaugeColor : .secondary)
                    Text(celsius != nil ? "Temperature" : "Unavailable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)
        }
    }
}
