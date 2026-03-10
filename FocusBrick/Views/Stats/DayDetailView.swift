import SwiftUI

/// Detail view showing all sessions for a specific day.
struct DayDetailView: View {
    let date: Date
    let sessions: [Session]

    @Environment(\.dismiss) private var dismiss

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Total Brick Time")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(totalDuration))
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Text("Sessions")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(sessions.count)")
                            .fontWeight(.semibold)
                    }
                }

                Section("Sessions") {
                    if sessions.isEmpty {
                        Text("No sessions on this day.")
                            .foregroundColor(.secondary)
                    }

                    ForEach(sessions) { session in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if let mode = session.mode {
                                    Text(mode.icon)
                                    Text(mode.name)
                                        .font(.headline)
                                }
                                Spacer()
                                Text(session.formattedDuration)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text(formatTime(session.startedAt))
                                if let end = session.endedAt {
                                    Text("–")
                                    Text(formatTime(end))
                                } else {
                                    Text("– Active")
                                        .foregroundColor(Color(hex: "2E86C1"))
                                }
                                Spacer()
                                Text(session.endReasonDisplay)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(dateFormatted)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
