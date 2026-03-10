import CoreData

@objc(Device)
public class Device: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var triggerType: String
    @NSManaged public var nfcUID: String?
    @NSManaged public var deviceUID: String
    @NSManaged public var pairedAt: Date
    @NSManaged public var emergencyUnbricksRemaining: Int16
    @NSManaged public var sessions: NSSet?

    var trigger: TriggerType {
        get { TriggerType(rawValue: triggerType) ?? .nfc }
        set { triggerType = newValue.rawValue }
    }

    var emergencyTokens: Int {
        get { Int(emergencyUnbricksRemaining) }
        set { emergencyUnbricksRemaining = Int16(newValue) }
    }
}

extension Device {
    static func create(
        name: String,
        triggerType: TriggerType = .nfc,
        nfcUID: String? = nil,
        in context: NSManagedObjectContext
    ) -> Device {
        let device = Device(context: context)
        device.id = UUID()
        device.name = name
        device.triggerType = triggerType.rawValue
        device.nfcUID = nfcUID
        device.deviceUID = nfcUID ?? UUID().uuidString
        device.pairedAt = Date()
        device.emergencyUnbricksRemaining = 5
        return device
    }

    static func fetchAll(in context: NSManagedObjectContext) -> [Device] {
        let request = NSFetchRequest<Device>(entityName: "Device")
        request.sortDescriptors = [NSSortDescriptor(key: "pairedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    static func findByNfcUID(_ uid: String, in context: NSManagedObjectContext) -> Device? {
        let request = NSFetchRequest<Device>(entityName: "Device")
        request.predicate = NSPredicate(format: "nfcUID == %@", uid)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }
}
