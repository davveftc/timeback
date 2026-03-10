import Foundation

/// Defines the hardware trigger mechanism used by a paired device.
enum TriggerType: String, Codable, CaseIterable {
    case nfc
    case otp
}
