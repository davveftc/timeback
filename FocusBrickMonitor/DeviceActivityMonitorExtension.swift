import DeviceActivity
import ManagedSettings
import CoreData

/// DeviceActivityMonitor extension that applies/removes shields on schedule.
/// Runs independently of the main app process.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("focusbrick.shields")
    )

    /// Called when a scheduled activity interval begins.
    /// Reads the mode ID from the activity name, loads blocked apps, and applies shields.
    override func intervalDidStart(for activity: DeviceActivityName) {
        // The activity name encodes the schedule ID and day.
        // Format: "{scheduleUUID}_day{dayNumber}"
        // We need to load the schedule from the shared Core Data store
        // to find which mode (and thus which apps) to block.
        let activityString = activity.rawValue
        let components = activityString.split(separator: "_")
        guard let scheduleUUIDString = components.first,
              let scheduleUUID = UUID(uuidString: String(scheduleUUIDString))
        else { return }

        // Load the shared Core Data store via App Group
        let model = PersistenceController.createManagedObjectModel()
        let container = NSPersistentContainer(name: "FocusBrickModel", managedObjectModel: model)

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier
        ) {
            let storeURL = containerURL.appendingPathComponent("FocusBrick.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            guard error == nil else { return }
        }

        let context = container.viewContext

        // Fetch the schedule
        let request = NSFetchRequest<Schedule>(entityName: "Schedule")
        request.predicate = NSPredicate(format: "id == %@", scheduleUUID as CVarArg)
        request.fetchLimit = 1

        guard let schedule = (try? context.fetch(request))?.first else { return }
        let mode = schedule.mode

        // Check if there's already a manual session active — manual takes priority
        if let activeSession = Session.fetchActive(in: context), !activeSession.isVirtualLock {
            return
        }

        // Apply shields
        store.shield.applications = mode.blockedAppTokens.isEmpty ? nil : mode.blockedAppTokens

        if !mode.blockedCategoryTokens.isEmpty {
            store.shield.applicationCategories = .specific(mode.blockedCategoryTokens)
        }

        if !mode.blockedWebDomainTokens.isEmpty {
            store.shield.webDomains = mode.blockedWebDomainTokens
        }
    }

    /// Called when a scheduled activity interval ends.
    /// Removes all shields unless a manual session is active.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Check for active manual session — don't clear if user manually bricked
        let model = PersistenceController.createManagedObjectModel()
        let container = NSPersistentContainer(name: "FocusBrickModel", managedObjectModel: model)

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: PersistenceController.appGroupIdentifier
        ) {
            let storeURL = containerURL.appendingPathComponent("FocusBrick.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, _ in }

        let context = container.viewContext
        if Session.fetchActive(in: context) != nil {
            // Manual session still active, don't remove shields
            return
        }

        store.clearAllSettings()
    }
}
