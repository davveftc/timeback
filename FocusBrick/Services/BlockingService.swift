import ManagedSettings
import FamilyControls

/// Applies and removes app shields using a named ManagedSettingsStore.
/// The store name is shared between the main app and extensions via App Group.
final class BlockingService: ObservableObject {
    static let storeName = ManagedSettingsStore.Name("focusbrick.shields")

    private let store: ManagedSettingsStore

    init() {
        store = ManagedSettingsStore(named: Self.storeName)
    }

    /// Apply shields for the given mode's blocked apps, categories, and web domains.
    func brick(
        appTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken> = [],
        webDomains: Set<WebDomainToken> = []
    ) {
        store.shield.applications = appTokens.isEmpty ? nil : appTokens

        if !categoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(categoryTokens)
        }

        if !webDomains.isEmpty {
            store.shield.webDomains = webDomains
        }
    }

    /// Remove all shields, unblocking all apps.
    func unbrick() {
        store.clearAllSettings()
    }

    /// Check if any application shields are currently active.
    var isBricked: Bool {
        store.shield.applications != nil
    }
}
