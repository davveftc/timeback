import SwiftUI

/// Usage statistics: daily/weekly brick time, bar chart, streaks.
struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var showDayDetail = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary cards
                    HStack(spacing: 16) {
                        StatCard(title: "Today", value: viewModel.todayFormatted, icon: "clock.fill")
                        StatCard(title: "This Week", value: viewModel.weekFormatted, icon: "calendar")
                    }
                    .padding(.horizontal)

                    // Bar chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 Days")
                            .font(.headline)
                            .padding(.horizontal)

                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(viewModel.dailyTimes, id: \.0) { date, time in
                                DayBarView(
                                    date: date,
                                    time: time,
                                    maxTime: viewModel.maxDailyTime,
                                    isSelected: viewModel.selectedDate == date
                                ) {
                                    viewModel.selectDay(date)
                                    showDayDetail = true
                                }
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 8)
                    .padding(.horizontal)

                    // Streaks and totals
                    HStack(spacing: 16) {
                        StatCard(title: "Total Sessions", value: "\(viewModel.totalSessions)", icon: "number")
                        StatCard(title: "Current Streak", value: "\(viewModel.currentStreak) days", icon: "flame.fill")
                    }
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        StatCard(title: "Longest Streak", value: "\(viewModel.longestStreak) days", icon: "trophy.fill")
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Empty state
                    if viewModel.totalSessions == 0 {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No sessions yet.\nBrick your phone to start tracking.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Stats")
            .onAppear { viewModel.refresh() }
            .sheet(isPresented: $showDayDetail) {
                if let date = viewModel.selectedDate {
                    DayDetailView(
                        date: date,
                        sessions: viewModel.selectedDaySessions
                    )
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color(hex: "2E86C1"))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct DayBarView: View {
    let date: Date
    let time: TimeInterval
    let maxTime: TimeInterval
    let isSelected: Bool
    let onTap: () -> Void

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var barHeight: CGFloat {
        guard maxTime > 0 else { return 4 }
        return max(4, CGFloat(time / maxTime) * 120)
    }

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color(hex: "2E86C1") : Color(hex: "2E86C1").opacity(0.5))
                .frame(height: barHeight)
            Text(dayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}
