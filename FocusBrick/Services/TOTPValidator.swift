import CryptoKit
import Foundation

/// TOTP generation and validation per RFC 6238.
/// Phase 2 implementation — stub for Phase 1.
struct TOTPValidator {
    let secret: SymmetricKey  // 256-bit
    let digits: Int           // 6
    let timeStep: TimeInterval // 30.0

    init(secret: SymmetricKey, digits: Int = 6, timeStep: TimeInterval = 30.0) {
        self.secret = secret
        self.digits = digits
        self.timeStep = timeStep
    }

    init(secretData: Data, digits: Int = 6, timeStep: TimeInterval = 30.0) {
        self.secret = SymmetricKey(data: secretData)
        self.digits = digits
        self.timeStep = timeStep
    }

    /// Generate TOTP code for the given date.
    func generateCode(at date: Date = .now) -> String {
        let counter = UInt64(date.timeIntervalSince1970 / timeStep)
        var bigEndian = counter.bigEndian
        let counterData = Data(bytes: &bigEndian, count: MemoryLayout<UInt64>.size)

        let hmac = HMAC<SHA256>.authenticationCode(for: counterData, using: secret)
        let hash = Data(hmac)

        let offset = Int(hash.last! & 0x0F)
        let truncated = hash.subdata(in: offset..<offset + 4)
            .withUnsafeBytes {
                $0.load(as: UInt32.self).bigEndian & 0x7FFFFFFF
            }

        let code = truncated % UInt32(pow(10, Double(digits)))
        return String(format: "%0\(digits)d", code)
    }

    /// Validate code against windows [-1, 0, +1].
    /// Returns true if valid AND not in usedCodes.
    func validate(code: String, usedCodes: inout Set<String>) -> Bool {
        guard !usedCodes.contains(code) else { return false }

        for offset in [-1.0, 0.0, 1.0] {
            let checkDate = Date().addingTimeInterval(offset * timeStep)
            if generateCode(at: checkDate) == code {
                usedCodes.insert(code)
                return true
            }
        }
        return false
    }

    /// Seconds remaining in current TOTP window.
    var secondsRemaining: Int {
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: timeStep)
        return Int(timeStep - elapsed)
    }

    /// Progress through current window (0.0 to 1.0).
    var windowProgress: Double {
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: timeStep)
        return elapsed / timeStep
    }
}
