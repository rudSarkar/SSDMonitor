import SwiftUI

@main
struct SSDMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // No windows — pure menu bar app
        Settings { EmptyView() }
    }
}
