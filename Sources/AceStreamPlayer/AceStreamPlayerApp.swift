import SwiftUI

@main
struct AceStreamPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var engine = EngineManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
                .onAppear { appDelegate.engine = engine }
        }
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var engine: EngineManager?

    func applicationWillTerminate(_ notification: Notification) {
        engine?.stopEngineSync()
    }
}
