import SwiftUI

/// Circular countdown ring used for OTP time window display (Phase 2).
/// Stub implementation for Phase 1.
struct CountdownRingView: View {
    let progress: CGFloat // 0.0 to 1.0
    let secondsRemaining: Int
    let isUrgent: Bool // < 5 seconds remaining

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)
                .frame(width: 60, height: 60)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isUrgent ? Color(hex: "E67E22") : Color(hex: "2E86C1"),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            // Center text
            if isUrgent {
                Text("Wait...")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "E67E22"))
            } else {
                Text("\(secondsRemaining)s")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.primary)
            }
        }
    }
}
