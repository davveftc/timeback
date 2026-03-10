import SwiftUI

/// Displays elapsed Brick time using SwiftUI's built-in timer.
/// Computed from session start date for accuracy across backgrounding.
struct FocusTimerView: View {
    let startDate: Date

    var body: some View {
        Text(startDate, style: .timer)
            .font(.system(size: 48, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .monospacedDigit()
    }
}
