import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover    = NSPopover()
    private var cancellables = Set<AnyCancellable>()
    private let monitor: MonitorService

    init(monitor: MonitorService) {
        self.monitor = monitor
        configureButton()
        configurePopover()

        // Update status bar text whenever stats or unit changes
        monitor.$stats
            .combineLatest(monitor.settings.$unit)
            .receive(on: RunLoop.main)
            .sink { [weak self] stats, unit in
                self?.updateTitle(stats: stats, unit: unit)
            }
            .store(in: &cancellables)
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .noImage
        button.action = #selector(togglePopover)
        button.target = self
        button.sendAction(on: .leftMouseUp)
        // Set a placeholder title
        updateTitle(stats: SSDStats(), unit: monitor.settings.unit)
    }

    private func configurePopover() {
        let contentView = PopoverContentView(monitor: monitor)
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.behavior  = .transient
        popover.animates  = true
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updateTitle(stats: SSDStats, unit: TemperatureUnit) {
        guard let button = statusItem.button else { return }

        let temp  = stats.formattedTemperature(in: unit)
        let read  = formatSpeed(stats.readSpeedMBs)
        let write = formatSpeed(stats.writeSpeedMBs)

        let full = "\(temp)  R:\(read)  W:\(write)"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11.5, weight: .regular)
        ]
        button.attributedTitle = NSAttributedString(string: full, attributes: attrs)
    }

    private func formatSpeed(_ mbs: Double) -> String {
        if mbs >= 1000 { return String(format: "%.1fG", mbs / 1000) }
        if mbs >= 1    { return String(format: "%.1fM", mbs) }
        return String(format: "%.0fK", mbs * 1024)
    }
}
