import CoreData

@objc(Schedule)
public class Schedule: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var daysOfWeek: NSArray // [Int], 1=Mon through 7=Sun
    @NSManaged public var startHour: Int16
    @NSManaged public var startMinute: Int16
    @NSManaged public var endHour: NSNumber? // 0-23, nil = no auto-end
    @NSManaged public var endMinute: NSNumber? // 0-59
    @NSManaged public var isEnabled: Bool
    @NSManaged public var mode: Mode

    var days: [Int] {
        get { (daysOfWeek as? [Int]) ?? [] }
        set { daysOfWeek = newValue as NSArray }
    }

    var startTimeComponents: DateComponents {
        DateComponents(hour: Int(startHour), minute: Int(startMinute))
    }

    var endTimeComponents: DateComponents? {
        guard let h = endHour?.intValue, let m = endMinute?.intValue else { return nil }
        return DateComponents(hour: h, minute: m)
    }

    var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = Int(startHour)
        components.minute = Int(startMinute)
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var endTimeFormatted: String? {
        guard let h = endHour?.intValue, let m = endMinute?.intValue else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = h
        components.minute = m
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    var daysFormatted: String {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let sorted = days.sorted()
        if sorted == [1, 2, 3, 4, 5, 6, 7] { return "Every day" }
        if sorted == [1, 2, 3, 4, 5] { return "Weekdays" }
        if sorted == [6, 7] { return "Weekends" }
        return sorted.map { dayNames[($0 - 1).clamped(to: 0...6)] }.joined(separator: ", ")
    }
}

extension Schedule {
    static let maxSchedules = 20

    static func create(
        mode: Mode,
        days: [Int],
        startHour: Int,
        startMinute: Int,
        endHour: Int? = nil,
        endMinute: Int? = nil,
        in context: NSManagedObjectContext
    ) -> Schedule {
        let schedule = Schedule(context: context)
        schedule.id = UUID()
        schedule.mode = mode
        schedule.daysOfWeek = days as NSArray
        schedule.startHour = Int16(startHour)
        schedule.startMinute = Int16(startMinute)
        schedule.endHour = endHour.map { NSNumber(value: $0) }
        schedule.endMinute = endMinute.map { NSNumber(value: $0) }
        schedule.isEnabled = true
        return schedule
    }

    static func fetchAll(in context: NSManagedObjectContext) -> [Schedule] {
        let request = NSFetchRequest<Schedule>(entityName: "Schedule")
        request.sortDescriptors = [NSSortDescriptor(key: "startHour", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
}

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
