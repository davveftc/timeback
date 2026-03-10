import CoreData
import Combine

/// Manages Brick session lifecycle and provides aggregated stats queries.
final class SessionManager: ObservableObject {
    @Published var activeSession: Session?

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
        self.activeSession = restoreActiveSession()
    }

    // MARK: - Session Lifecycle

    /// Start a new Brick session.
    @discardableResult
    func startSession(
        device: Device,
        mode: Mode,
        triggerType: TriggerType = .nfc,
        isVirtualLock: Bool = false
    ) -> Session {
        let session = Session.create(
            device: device,
            mode: mode,
            triggerType: triggerType,
            isVirtualLock: isVirtualLock,
            in: context
        )
        save()
        activeSession = session
        return session
    }

    /// End the active session with the given reason.
    func endSession(reason: String) {
        guard let session = activeSession else { return }
        session.end(reason: reason)
        save()
        activeSession = nil
    }

    /// Restore an active session on app launch (shields persist across force-quit/reboot).
    func restoreActiveSession() -> Session? {
        Session.fetchActive(in: context)
    }

    // MARK: - Stats Queries

    /// Total brick time for a specific day.
    func totalBrickTime(for date: Date) -> TimeInterval {
        let sessions = Session.fetchForDay(date, in: context)
        return sessions.reduce(0) { $0 + $1.duration }
    }

    /// Total brick time for the current week (Monday through today).
    func totalBrickTimeThisWeek() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))
        else { return 0 }

        let request = NSFetchRequest<Session>(entityName: "Session")
        request.predicate = NSPredicate(
            format: "startedAt >= %@",
            weekStart as NSDate
        )
        let sessions = (try? context.fetch(request)) ?? []
        return sessions.reduce(0) { $0 + $1.duration }
    }

    /// Sessions for a specific day.
    func sessionsForDay(_ date: Date) -> [Session] {
        Session.fetchForDay(date, in: context)
    }

    /// Daily brick times for the last 7 days.
    func dailyBrickTimes() -> [(Date, TimeInterval)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return (date, totalBrickTime(for: date))
        }
    }

    /// Total session count.
    func totalSessionCount() -> Int {
        let request = NSFetchRequest<Session>(entityName: "Session")
        return (try? context.count(for: request)) ?? 0
    }

    /// Current streak: consecutive days with at least 1 hour of brick time.
    func currentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let time = totalBrickTime(for: checkDate)
            if time >= 3600 { // 1 hour minimum
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                break
            }
        }
        return streak
    }

    /// Longest streak ever: consecutive days with at least 1 hour of brick time.
    func longestStreak() -> Int {
        let request = NSFetchRequest<Session>(entityName: "Session")
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: true)]
        guard let sessions = try? context.fetch(request), !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current

        // Get the date range
        guard let firstDate = sessions.first?.startedAt,
              let lastDate = sessions.last?.startedAt
        else { return 0 }

        let startDay = calendar.startOfDay(for: firstDate)
        let endDay = calendar.startOfDay(for: lastDate)

        var longest = 0
        var current = 0
        var checkDate = startDay

        while checkDate <= endDay {
            let time = totalBrickTime(for: checkDate)
            if time >= 3600 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
            checkDate = nextDay
        }

        return longest
    }

    // MARK: - Private

    private func save() {
        PersistenceController.shared.save()
    }
}
