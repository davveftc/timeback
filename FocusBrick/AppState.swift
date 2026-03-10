import SwiftUI
import FamilyControls
import Combine

/// Global app state observable. Shared across views via @EnvironmentObject.
/// Tracks authorization status, brick state, and active session.
@MainActor
final class AppState: ObservableObject {
    @Published var isAuthorized = false
    @Published var isBricked = false
    @Published var activeSession: Session?
    @Published var pairedDevices: [Device] = []

    private let context = PersistenceController.shared.viewContext
    private var cancellables = Set<AnyCancellable>()

    init() {
        checkAuthorization()
        loadDevices()
        restoreSession()
        observeAuthorizationChanges()
    }

    // MARK: - Authorization

    func checkAuthorization() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private func observeAuthorizationChanges() {
        // Listen for authorization status changes (e.g., user revokes in Settings)
        Task {
            for await event in AuthorizationCenter.shared.events {
                switch event {
                case .authorized:
                    isAuthorized = true
                case .revoked:
                    isAuthorized = false
                default:
                    break
                }
            }
        }
    }

    // MARK: - Device Management

    func loadDevices() {
        pairedDevices = Device.fetchAll(in: context)
    }

    // MARK: - Session Restoration

    func restoreSession() {
        if let session = Session.fetchActive(in: context) {
            activeSession = session
            isBricked = true
        }
    }

    // MARK: - Widget & Live Activity Updates

    func notifyWidgetUpdate() {
        // Import WidgetKit in the main app to trigger timeline reload
        // WidgetCenter.shared.reloadAllTimelines()
    }
}
