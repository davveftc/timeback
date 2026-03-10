import SwiftUI

/// Emergency unbrick confirmation with 10-second hold-to-confirm.
struct EmergencyUnbrickSheet: View {
    let remainingTokens: Int
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTimer: Timer?

    private let holdDuration: TimeInterval = 10.0

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .padding(.top, 32)

            Text("Emergency Unbrick")
                .font(.title2)
                .fontWeight(.bold)

            Text("This will use 1 of your emergency tokens.\nThis action is permanent and cannot be undone.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Token count
            HStack {
                Image(systemName: "ticket.fill")
                    .foregroundColor(.orange)
                Text("\(remainingTokens) of 5 remaining")
                    .fontWeight(.semibold)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            // Hold-to-confirm button
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 6)
                    .frame(width: 100, height: 100)

                // Progress circle
                Circle()
                    .trim(from: 0, to: holdProgress)
                    .stroke(
                        Color.red,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                // Label
                VStack(spacing: 2) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title3)
                    Text(isHolding ? "\(Int((1 - holdProgress) * holdDuration))s" : "Hold")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isHolding ? .red : .primary)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isHolding { startHold() }
                    }
                    .onEnded { _ in
                        cancelHold()
                    }
            )

            Text("Press and hold for 10 seconds")
                .font(.caption)
                .foregroundColor(.secondary)

            // Cancel button
            Button("Cancel") {
                dismiss()
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
        .interactiveDismissDisabled(isHolding)
    }

    private func startHold() {
        isHolding = true
        holdProgress = 0

        let interval: TimeInterval = 0.05
        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            holdProgress += CGFloat(interval / holdDuration)

            if holdProgress >= 1.0 {
                holdTimer?.invalidate()
                holdTimer = nil
                completeHold()
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        holdProgress = 0
        holdTimer?.invalidate()
        holdTimer = nil
    }

    private func completeHold() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)

        onConfirm()
        dismiss()
    }
}
