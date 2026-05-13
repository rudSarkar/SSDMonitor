import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var monitorService:      MonitorService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = UserSettings()
        let monitor  = MonitorService(settings: settings)

        monitorService      = monitor
        statusBarController = StatusBarController(monitor: monitor)

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitorService?.stop()
    }
}
