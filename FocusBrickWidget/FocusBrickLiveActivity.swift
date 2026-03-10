import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Activity Attributes

struct FocusBrickActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isBricked: Bool
    }

    var modeName: String
    var modeIcon: String
    var sessionStartedAt: Date
}

// MARK: - Live Activity Widget

struct FocusBrickLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusBrickActivityAttributes.self) { context in
            // Lock screen / banner presentation
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Text(context.attributes.modeIcon)
                        Text(context.attributes.modeName)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.sessionStartedAt, style: .timer)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Your phone is Bricked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Text(context.attributes.modeIcon)
                        .font(.caption2)
                    Text("Bricked")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
            } compactTrailing: {
                Text(context.attributes.sessionStartedAt, style: .timer)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .monospacedDigit()
            } minimal: {
                Text(context.attributes.modeIcon)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<FocusBrickActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(context.attributes.modeIcon)
                    Text(context.attributes.modeName)
                        .font(.headline)
                }
                Text("Your phone is Bricked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(context.attributes.sessionStartedAt, style: .timer)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .monospacedDigit()
        }
        .padding()
        .background(Color(hex: "1C2833"))
        .foregroundColor(.white)
    }
}

// MARK: - Live Activity Manager

enum LiveActivityManager {
    private static var currentActivity: Activity<FocusBrickActivityAttributes>?

    /// Start a Live Activity for a Brick session.
    static func start(modeName: String, modeIcon: String, sessionStartedAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = FocusBrickActivityAttributes(
            modeName: modeName,
            modeIcon: modeIcon,
            sessionStartedAt: sessionStartedAt
        )
        let state = FocusBrickActivityAttributes.ContentState(isBricked: true)
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    /// End the current Live Activity.
    static func stop() {
        Task {
            let state = FocusBrickActivityAttributes.ContentState(isBricked: false)
            let content = ActivityContent(state: state, staleDate: nil)
            await currentActivity?.end(content, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}
