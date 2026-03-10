import SwiftUI
import FamilyControls

/// @main entry point for the FocusBrick app.
@main
struct FocusBrickApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .environmentObject(appState)
            .onAppear {
                appState.checkAuthorization()
                appState.restoreSession()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Re-check authorization when app returns to foreground
                // (user may have revoked in Settings)
                appState.checkAuthorization()
                appState.restoreSession()
            }
        }
    }
}
