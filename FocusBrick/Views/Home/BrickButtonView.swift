import SwiftUI

/// Large circular Brick button with long-press support for virtual lock.
struct BrickButtonView: View {
    let icon: String
    let isEnabled: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var longPressProgress: CGFloat = 0
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?

    private let buttonSize: CGFloat = 120
    private let longPressDuration: TimeInterval = 5.0 // 5 seconds for virtual lock

    var body: some View {
        ZStack {
            // Background circle with progress ring for long press
            Circle()
                .fill(isEnabled ? Color(hex: "2E86C1") : Color(.systemGray4))
                .frame(width: buttonSize, height: buttonSize)

            // Long press progress ring
            if isLongPressing {
                Circle()
                    .trim(from: 0, to: longPressProgress)
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: buttonSize + 8, height: buttonSize + 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: longPressProgress)
            }

            // Icon
            Text(icon)
                .font(.system(size: 32))
        }
        .opacity(isEnabled ? 1 : 0.6)
        .scaleEffect(isLongPressing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLongPressing)
        .onTapGesture {
            guard isEnabled else { return }
            onTap()
        }
        .onLongPressGesture(minimumDuration: longPressDuration, pressing: { pressing in
            guard isEnabled else { return }
            if pressing {
                startLongPress()
            } else {
                cancelLongPress()
            }
        }) {
            completeLongPress()
        }
    }

    private func startLongPress() {
        isLongPressing = true
        longPressProgress = 0

        // Update progress every 50ms
        let interval: TimeInterval = 0.05
        longPressTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            longPressProgress += CGFloat(interval / longPressDuration)
            if longPressProgress >= 1.0 {
                longPressTimer?.invalidate()
            }
        }
    }

    private func cancelLongPress() {
        isLongPressing = false
        longPressProgress = 0
        longPressTimer?.invalidate()
        longPressTimer = nil
    }

    private func completeLongPress() {
        cancelLongPress()
        onLongPress()
    }
}
