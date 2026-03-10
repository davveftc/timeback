import SwiftUI
import Combine

/// Phase 2 stub: Drives the OTP code entry screen.
/// Will be fully implemented when OTP hardware token support is added.
@MainActor
final class OTPEntryViewModel: ObservableObject {
    @Published var digits: [String] = Array(repeating: "", count: 6)
    @Published var activeIndex: Int = 0
    @Published var errorMessage: String?
    @Published var isValidated = false
    @Published var isRateLimited = false
    @Published var secondsRemaining: Int = 30
    @Published var windowProgress: Double = 0

    private var attemptsThisWindow: Int = 0
    private var usedCodes: Set<String> = []
    private var validator: TOTPValidator?
    private var timer: Timer?

    // Phase 2: Initialize with device secret from Keychain
    func configure(with secretData: Data) {
        validator = TOTPValidator(secretData: secretData)
        startTimer()
    }

    func enterDigit(_ digit: String) {
        guard activeIndex < 6, !isRateLimited else { return }
        digits[activeIndex] = digit
        activeIndex += 1

        // Auto-validate on 6th digit
        if activeIndex == 6 {
            validate()
        }
    }

    func deleteDigit() {
        guard activeIndex > 0 else { return }
        activeIndex -= 1
        digits[activeIndex] = ""
    }

    func clearAll() {
        digits = Array(repeating: "", count: 6)
        activeIndex = 0
        errorMessage = nil
    }

    private func validate() {
        let code = digits.joined()
        guard let validator = validator else { return }

        // Rate limiting: max 3 attempts per 30-second window
        if attemptsThisWindow >= 3 {
            isRateLimited = true
            errorMessage = "Too many attempts. Wait for the next code."
            clearAll()
            return
        }

        attemptsThisWindow += 1

        if usedCodes.contains(code) {
            errorMessage = "Code already used. Wait for the next code."
            clearAll()
            return
        }

        if validator.validate(code: code, usedCodes: &usedCodes) {
            isValidated = true
            errorMessage = nil
        } else {
            errorMessage = "Incorrect code"
            clearAll()
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let validator = self.validator else { return }
                self.secondsRemaining = validator.secondsRemaining
                self.windowProgress = validator.windowProgress

                // Reset rate limit and attempt count on new window
                if self.secondsRemaining >= 29 {
                    self.attemptsThisWindow = 0
                    self.isRateLimited = false
                }
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
