import SwiftUI

/// Phase 2 stub: 6-digit OTP code entry screen.
/// Will be fully implemented when OTP hardware token support is added.
struct OTPEntryView: View {
    @StateObject private var viewModel = OTPEntryViewModel()
    @Environment(\.dismiss) private var dismiss

    let deviceName: String
    let deviceIcon: String
    let secretData: Data
    let onValidated: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Cancel button
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top)

            // Device indicator
            HStack(spacing: 4) {
                Text(deviceIcon)
                Text(deviceName)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }

            // Instruction
            Text("Enter the code on your FocusBrick")
                .font(.system(size: 18))
                .foregroundColor(.secondary)

            // 6 digit boxes
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    DigitBox(
                        digit: viewModel.digits[index],
                        isActive: index == viewModel.activeIndex,
                        isFilled: !viewModel.digits[index].isEmpty
                    )
                }
            }

            // Countdown ring
            CountdownRingView(
                progress: CGFloat(1.0 - viewModel.windowProgress),
                secondsRemaining: viewModel.secondsRemaining,
                isUrgent: viewModel.secondsRemaining < 5
            )

            // Status
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
            }

            if viewModel.isValidated {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Verified!")
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            viewModel.configure(with: secretData)
        }
        .onChange(of: viewModel.isValidated) { validated in
            if validated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onValidated()
                    dismiss()
                }
            }
        }
    }
}

/// Individual digit box for OTP entry.
struct DigitBox: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool

    var body: some View {
        Text(digit)
            .font(.system(size: 36, weight: .bold, design: .monospaced))
            .frame(width: 56, height: 64)
            .background(
                isFilled
                    ? Color(hex: "2E86C1").opacity(0.1)
                    : Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isActive ? Color(hex: "2E86C1") : Color.clear,
                        lineWidth: 2
                    )
            )
    }
}
