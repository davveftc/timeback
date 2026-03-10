import DeviceActivity
import FamilyControls
import CoreData

/// Manages DeviceActivityCenter schedules for auto-brick/unbrick.
/// Schedules run via the DeviceActivityMonitor extension even when the app is killed.
final class ScheduleService: ObservableObject {
    private let center = DeviceActivityCenter()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    /// Register all enabled schedules with DeviceActivityCenter.
    func syncSchedules() {
        // Stop all existing monitoring first
        center.stopMonitoring()

        let schedules = Schedule.fetchAll(in: context)
        for schedule in schedules where schedule.isEnabled {
            registerSchedule(schedule)
        }
    }

    /// Register a single schedule with DeviceActivityCenter.
    func registerSchedule(_ schedule: Schedule) {
        let activityName = DeviceActivityName(schedule.id.uuidString)

        for day in schedule.days {
            let dayActivityName = DeviceActivityName("\(schedule.id.uuidString)_day\(day)")

            var startComponents = DateComponents()
            startComponents.hour = Int(schedule.startHour)
            startComponents.minute = Int(schedule.startMinute)
            startComponents.weekday = isoToGregorian(day)

            let endComponents: DateComponents
            if let endTime = schedule.endTimeComponents {
                var ec = endTime
                ec.weekday = isoToGregorian(day)
                endComponents = ec
            } else {
                // If no end time, set end to 23:59
                var ec = DateComponents()
                ec.hour = 23
                ec.minute = 59
                ec.weekday = isoToGregorian(day)
                endComponents = ec
            }

            let deviceSchedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: true
            )

            do {
                try center.startMonitoring(dayActivityName, during: deviceSchedule)
            } catch {
                print("Failed to register schedule \(schedule.id): \(error)")
            }
        }
    }

    /// Stop monitoring a specific schedule.
    func unregisterSchedule(_ schedule: Schedule) {
        for day in schedule.days {
            let dayActivityName = DeviceActivityName("\(schedule.id.uuidString)_day\(day)")
            center.stopMonitoring([dayActivityName])
        }
    }

    /// Create and register a new schedule.
    @discardableResult
    func createSchedule(
        mode: Mode,
        days: [Int],
        startHour: Int,
        startMinute: Int,
        endHour: Int? = nil,
        endMinute: Int? = nil
    ) -> Schedule {
        let schedule = Schedule.create(
            mode: mode,
            days: days,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            in: context
        )
        PersistenceController.shared.save()
        registerSchedule(schedule)
        return schedule
    }

    /// Delete a schedule and stop its monitoring.
    func deleteSchedule(_ schedule: Schedule) {
        unregisterSchedule(schedule)
        context.delete(schedule)
        PersistenceController.shared.save()
    }

    /// Toggle a schedule's enabled state.
    func toggleSchedule(_ schedule: Schedule) {
        schedule.isEnabled.toggle()
        PersistenceController.shared.save()

        if schedule.isEnabled {
            registerSchedule(schedule)
        } else {
            unregisterSchedule(schedule)
        }
    }

    // MARK: - Helpers

    /// Convert ISO weekday (1=Mon..7=Sun) to Calendar.gregorian weekday (1=Sun..7=Sat).
    private func isoToGregorian(_ isoDay: Int) -> Int {
        isoDay == 7 ? 1 : isoDay + 1
    }
}
