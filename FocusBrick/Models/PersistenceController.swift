import CoreData

/// Core Data stack configured with an App Group shared container
/// so the main app and extensions (DeviceActivityMonitor, Widget) share data.
final class PersistenceController {
    static let shared = PersistenceController()

    static let appGroupIdentifier = "group.com.focusbrick.shared"

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        let model = Self.createManagedObjectModel()
        container = NSPersistentContainer(name: "FocusBrickModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            // Use App Group shared container for cross-target data sharing
            if let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
            ) {
                let storeURL = containerURL.appendingPathComponent("FocusBrick.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
                container.persistentStoreDescriptions = [description]
            }
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data store failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Core Data Model

    static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- Device Entity ---
        let deviceEntity = NSEntityDescription()
        deviceEntity.name = "Device"
        deviceEntity.managedObjectClassName = "Device"

        let deviceId = NSAttributeDescription()
        deviceId.name = "id"
        deviceId.attributeType = .UUIDAttributeType
        deviceId.isOptional = false

        let deviceName = NSAttributeDescription()
        deviceName.name = "name"
        deviceName.attributeType = .stringAttributeType
        deviceName.isOptional = false

        let deviceTriggerType = NSAttributeDescription()
        deviceTriggerType.name = "triggerType"
        deviceTriggerType.attributeType = .stringAttributeType
        deviceTriggerType.isOptional = false
        deviceTriggerType.defaultValue = "nfc"

        let deviceNfcUID = NSAttributeDescription()
        deviceNfcUID.name = "nfcUID"
        deviceNfcUID.attributeType = .stringAttributeType
        deviceNfcUID.isOptional = true

        let deviceUID = NSAttributeDescription()
        deviceUID.name = "deviceUID"
        deviceUID.attributeType = .stringAttributeType
        deviceUID.isOptional = false

        let devicePairedAt = NSAttributeDescription()
        devicePairedAt.name = "pairedAt"
        devicePairedAt.attributeType = .dateAttributeType
        devicePairedAt.isOptional = false

        let deviceEmergencyUnbricks = NSAttributeDescription()
        deviceEmergencyUnbricks.name = "emergencyUnbricksRemaining"
        deviceEmergencyUnbricks.attributeType = .integer16AttributeType
        deviceEmergencyUnbricks.isOptional = false
        deviceEmergencyUnbricks.defaultValue = 5

        deviceEntity.properties = [
            deviceId, deviceName, deviceTriggerType, deviceNfcUID,
            deviceUID, devicePairedAt, deviceEmergencyUnbricks
        ]

        // --- Mode Entity ---
        let modeEntity = NSEntityDescription()
        modeEntity.name = "Mode"
        modeEntity.managedObjectClassName = "Mode"

        let modeId = NSAttributeDescription()
        modeId.name = "id"
        modeId.attributeType = .UUIDAttributeType
        modeId.isOptional = false

        let modeName = NSAttributeDescription()
        modeName.name = "name"
        modeName.attributeType = .stringAttributeType
        modeName.isOptional = false

        let modeIcon = NSAttributeDescription()
        modeIcon.name = "icon"
        modeIcon.attributeType = .stringAttributeType
        modeIcon.isOptional = false
        modeIcon.defaultValue = "💼"

        let modeBlockedAppTokensData = NSAttributeDescription()
        modeBlockedAppTokensData.name = "blockedAppTokensData"
        modeBlockedAppTokensData.attributeType = .binaryDataAttributeType
        modeBlockedAppTokensData.isOptional = false

        let modeBlockedCategoryTokensData = NSAttributeDescription()
        modeBlockedCategoryTokensData.name = "blockedCategoryTokensData"
        modeBlockedCategoryTokensData.attributeType = .binaryDataAttributeType
        modeBlockedCategoryTokensData.isOptional = true

        let modeBlockedWebDomainsData = NSAttributeDescription()
        modeBlockedWebDomainsData.name = "blockedWebDomainsData"
        modeBlockedWebDomainsData.attributeType = .binaryDataAttributeType
        modeBlockedWebDomainsData.isOptional = true

        let modeIsDefault = NSAttributeDescription()
        modeIsDefault.name = "isDefault"
        modeIsDefault.attributeType = .booleanAttributeType
        modeIsDefault.isOptional = false
        modeIsDefault.defaultValue = false

        let modeCreatedAt = NSAttributeDescription()
        modeCreatedAt.name = "createdAt"
        modeCreatedAt.attributeType = .dateAttributeType
        modeCreatedAt.isOptional = false

        let modeUpdatedAt = NSAttributeDescription()
        modeUpdatedAt.name = "updatedAt"
        modeUpdatedAt.attributeType = .dateAttributeType
        modeUpdatedAt.isOptional = false

        modeEntity.properties = [
            modeId, modeName, modeIcon, modeBlockedAppTokensData,
            modeBlockedCategoryTokensData, modeBlockedWebDomainsData,
            modeIsDefault, modeCreatedAt, modeUpdatedAt
        ]

        // --- Session Entity ---
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "Session"
        sessionEntity.managedObjectClassName = "Session"

        let sessionId = NSAttributeDescription()
        sessionId.name = "id"
        sessionId.attributeType = .UUIDAttributeType
        sessionId.isOptional = false

        let sessionStartedAt = NSAttributeDescription()
        sessionStartedAt.name = "startedAt"
        sessionStartedAt.attributeType = .dateAttributeType
        sessionStartedAt.isOptional = false

        let sessionEndedAt = NSAttributeDescription()
        sessionEndedAt.name = "endedAt"
        sessionEndedAt.attributeType = .dateAttributeType
        sessionEndedAt.isOptional = true

        let sessionDurationSeconds = NSAttributeDescription()
        sessionDurationSeconds.name = "durationSeconds"
        sessionDurationSeconds.attributeType = .integer32AttributeType
        sessionDurationSeconds.isOptional = false
        sessionDurationSeconds.defaultValue = 0

        let sessionTriggerType = NSAttributeDescription()
        sessionTriggerType.name = "triggerType"
        sessionTriggerType.attributeType = .stringAttributeType
        sessionTriggerType.isOptional = false
        sessionTriggerType.defaultValue = "nfc"

        let sessionEndReason = NSAttributeDescription()
        sessionEndReason.name = "endReason"
        sessionEndReason.attributeType = .stringAttributeType
        sessionEndReason.isOptional = true

        let sessionIsVirtualLock = NSAttributeDescription()
        sessionIsVirtualLock.name = "isVirtualLock"
        sessionIsVirtualLock.attributeType = .booleanAttributeType
        sessionIsVirtualLock.isOptional = false
        sessionIsVirtualLock.defaultValue = false

        sessionEntity.properties = [
            sessionId, sessionStartedAt, sessionEndedAt,
            sessionDurationSeconds, sessionTriggerType,
            sessionEndReason, sessionIsVirtualLock
        ]

        // --- Schedule Entity ---
        let scheduleEntity = NSEntityDescription()
        scheduleEntity.name = "Schedule"
        scheduleEntity.managedObjectClassName = "Schedule"

        let scheduleId = NSAttributeDescription()
        scheduleId.name = "id"
        scheduleId.attributeType = .UUIDAttributeType
        scheduleId.isOptional = false

        let scheduleDaysOfWeek = NSAttributeDescription()
        scheduleDaysOfWeek.name = "daysOfWeek"
        scheduleDaysOfWeek.attributeType = .transformableAttributeType
        scheduleDaysOfWeek.valueTransformerName = "NSSecureUnarchiveFromData"
        scheduleDaysOfWeek.isOptional = false

        let scheduleStartHour = NSAttributeDescription()
        scheduleStartHour.name = "startHour"
        scheduleStartHour.attributeType = .integer16AttributeType
        scheduleStartHour.isOptional = false

        let scheduleStartMinute = NSAttributeDescription()
        scheduleStartMinute.name = "startMinute"
        scheduleStartMinute.attributeType = .integer16AttributeType
        scheduleStartMinute.isOptional = false

        let scheduleEndHour = NSAttributeDescription()
        scheduleEndHour.name = "endHour"
        scheduleEndHour.attributeType = .integer16AttributeType
        scheduleEndHour.isOptional = true

        let scheduleEndMinute = NSAttributeDescription()
        scheduleEndMinute.name = "endMinute"
        scheduleEndMinute.attributeType = .integer16AttributeType
        scheduleEndMinute.isOptional = true

        let scheduleIsEnabled = NSAttributeDescription()
        scheduleIsEnabled.name = "isEnabled"
        scheduleIsEnabled.attributeType = .booleanAttributeType
        scheduleIsEnabled.isOptional = false
        scheduleIsEnabled.defaultValue = true

        scheduleEntity.properties = [
            scheduleId, scheduleDaysOfWeek, scheduleStartHour,
            scheduleStartMinute, scheduleEndHour, scheduleEndMinute,
            scheduleIsEnabled
        ]

        // --- Relationships ---

        // Device -> Sessions (one-to-many)
        let deviceToSessions = NSRelationshipDescription()
        deviceToSessions.name = "sessions"
        deviceToSessions.destinationEntity = sessionEntity
        deviceToSessions.isOptional = true
        deviceToSessions.deleteRule = .cascadeDeleteRule

        let sessionToDevice = NSRelationshipDescription()
        sessionToDevice.name = "device"
        sessionToDevice.destinationEntity = deviceEntity
        sessionToDevice.maxCount = 1
        sessionToDevice.isOptional = true

        deviceToSessions.inverseRelationship = sessionToDevice
        sessionToDevice.inverseRelationship = deviceToSessions

        // Mode -> Sessions (one-to-many)
        let modeToSessions = NSRelationshipDescription()
        modeToSessions.name = "sessions"
        modeToSessions.destinationEntity = sessionEntity
        modeToSessions.isOptional = true
        modeToSessions.deleteRule = .nullifyDeleteRule

        let sessionToMode = NSRelationshipDescription()
        sessionToMode.name = "mode"
        sessionToMode.destinationEntity = modeEntity
        sessionToMode.maxCount = 1
        sessionToMode.isOptional = true

        modeToSessions.inverseRelationship = sessionToMode
        sessionToMode.inverseRelationship = modeToSessions

        // Mode -> Schedules (one-to-many)
        let modeToSchedules = NSRelationshipDescription()
        modeToSchedules.name = "schedules"
        modeToSchedules.destinationEntity = scheduleEntity
        modeToSchedules.isOptional = true
        modeToSchedules.deleteRule = .cascadeDeleteRule

        let scheduleToMode = NSRelationshipDescription()
        scheduleToMode.name = "mode"
        scheduleToMode.destinationEntity = modeEntity
        scheduleToMode.maxCount = 1
        scheduleToMode.isOptional = false

        modeToSchedules.inverseRelationship = scheduleToMode
        scheduleToMode.inverseRelationship = modeToSchedules

        // Add relationships to entities
        deviceEntity.properties.append(contentsOf: [deviceToSessions])
        sessionEntity.properties.append(contentsOf: [sessionToDevice, sessionToMode])
        modeEntity.properties.append(contentsOf: [modeToSessions, modeToSchedules])
        scheduleEntity.properties.append(contentsOf: [scheduleToMode])

        model.entities = [deviceEntity, modeEntity, sessionEntity, scheduleEntity]
        return model
    }

    // MARK: - Convenience

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Core Data save error: \(nsError), \(nsError.userInfo)")
        }
    }

    /// Preview/testing instance with in-memory store
    static var preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
}
