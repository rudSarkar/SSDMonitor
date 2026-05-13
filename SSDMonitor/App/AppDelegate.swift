import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var monitorService:      MonitorService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure no dock icon or empty windows appear (belt-and-suspenders with LSUIElement)
        NSApp.setActivationPolicy(.accessory)

        let settings = UserSettings()
        let monitor  = MonitorService(settings: settings)

        monitorService      = monitor
        statusBarController = StatusBarController(monitor: monitor)

        monitor.start()

        // Close any regular window SwiftUI may have opened (e.g. the Settings scene).
        // Exclude NSStatusBarWindow — closing that removes the menu bar item.
        NSApp.windows
            .filter { !$0.className.contains("StatusBar") }
            .forEach { $0.close() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitorService?.stop()
    }
}
