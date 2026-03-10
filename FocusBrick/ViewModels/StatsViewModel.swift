import SwiftUI
import Combine

/// Aggregated session stats for the Stats tab.
@MainActor
final class StatsViewModel: ObservableObject {
    @Published var todayBrickTime: TimeInterval = 0
    @Published var weekBrickTime: TimeInterval = 0
    @Published var dailyTimes: [(Date, TimeInterval)] = []
    @Published var totalSessions: Int = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var selectedDaySessions: [Session] = []
    @Published var selectedDate: Date?

    private let sessionManager: SessionManager

    init(sessionManager: SessionManager = SessionManager()) {
        self.sessionManager = sessionManager
    }

    func refresh() {
        todayBrickTime = sessionManager.totalBrickTime(for: Date())
        weekBrickTime = sessionManager.totalBrickTimeThisWeek()
        dailyTimes = sessionManager.dailyBrickTimes()
        totalSessions = sessionManager.totalSessionCount()
        currentStreak = sessionManager.currentStreak()
        longestStreak = sessionManager.longestStreak()
    }

    func selectDay(_ date: Date) {
        selectedDate = date
        selectedDaySessions = sessionManager.sessionsForDay(date)
    }

    // MARK: - Formatted Values

    var todayFormatted: String {
        formatDuration(todayBrickTime)
    }

    var weekFormatted: String {
        formatDuration(weekBrickTime)
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Maximum value in daily times for chart scaling.
    var maxDailyTime: TimeInterval {
        dailyTimes.map(\.1).max() ?? 1
    }
}
