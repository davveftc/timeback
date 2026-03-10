import CoreData

@objc(Session)
public class Session: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var startedAt: Date
    @NSManaged public var endedAt: Date?
    @NSManaged public var durationSeconds: Int32
    @NSManaged public var triggerType: String
    @NSManaged public var endReason: String?
    @NSManaged public var isVirtualLock: Bool
    @NSManaged public var device: Device?
    @NSManaged public var mode: Mode?

    var trigger: TriggerType {
        get { TriggerType(rawValue: triggerType) ?? .nfc }
        set { triggerType = newValue.rawValue }
    }

    var isActive: Bool {
        endedAt == nil
    }

    var duration: TimeInterval {
        if let endedAt = endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    /// Formatted duration string (e.g., "2h 15m")
    var formattedDuration: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// End reason display text
    var endReasonDisplay: String {
        switch endReason {
        case "nfc_tap": return "NFC Tap"
        case "otp_code": return "OTP Code"
        case "emergency": return "Emergency"
        case "schedule": return "Schedule"
        case "virtual_lock": return "Virtual Lock"
        default: return endReason ?? "Active"
        }
    }
}

extension Session {
    static func create(
        device: Device,
        mode: Mode,
        triggerType: TriggerType = .nfc,
        isVirtualLock: Bool = false,
        in context: NSManagedObjectContext
    ) -> Session {
        let session = Session(context: context)
        session.id = UUID()
        session.startedAt = Date()
        session.triggerType = triggerType.rawValue
        session.isVirtualLock = isVirtualLock
        session.device = device
        session.mode = mode
        session.durationSeconds = 0
        return session
    }

    func end(reason: String) {
        self.endedAt = Date()
        self.endReason = reason
        self.durationSeconds = Int32(endedAt!.timeIntervalSince(startedAt))
    }

    static func fetchActive(in context: NSManagedObjectContext) -> Session? {
        let request = NSFetchRequest<Session>(entityName: "Session")
        request.predicate = NSPredicate(format: "endedAt == nil")
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    static func fetchForDay(_ date: Date, in context: NSManagedObjectContext) -> [Session] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request = NSFetchRequest<Session>(entityName: "Session")
        request.predicate = NSPredicate(
            format: "startedAt >= %@ AND startedAt < %@",
            startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
}
