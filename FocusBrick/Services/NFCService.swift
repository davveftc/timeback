import CoreNFC
import Combine

/// Wraps Core NFC to read NTAG215/216 tag UIDs.
/// Provides async/await interface via CheckedContinuation.
final class NFCService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var lastError: String?

    private var continuation: CheckedContinuation<String, Error>?

    /// Start NFC scanning. Returns the tag UID as a colon-separated hex string.
    /// Throws if NFC is unavailable, user cancels, or read fails.
    func scanTag() async throws -> String {
        guard NFCTagReaderSession.readingAvailable else {
            throw NFCError.notAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            DispatchQueue.main.async {
                self.isScanning = true
                self.lastError = nil
            }

            let session = NFCTagReaderSession(
                pollingOption: [.iso14443],
                delegate: self
            )
            session?.alertMessage = "Hold your iPhone near your FocusBrick device."
            session?.begin()
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCService: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // NFC session is active and scanning
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
        }

        // User cancellation is not an error we need to surface
        let nfcError = error as? NFCReaderError
        if nfcError?.code == .readerSessionInvalidationErrorUserCanceled {
            continuation?.resume(throwing: NFCError.userCancelled)
            continuation = nil
            return
        }

        if nfcError?.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
            // This is a success invalidation from our explicit invalidate call
            return
        }

        let message = error.localizedDescription
        DispatchQueue.main.async {
            self.lastError = message
        }
        continuation?.resume(throwing: NFCError.readFailed(message))
        continuation = nil
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag detected.")
            return
        }

        session.connect(to: tag) { [weak self] error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                return
            }

            // Extract the UID from the tag
            let uid: Data?
            switch tag {
            case .miFare(let miFareTag):
                uid = miFareTag.identifier
            case .iso7816(let iso7816Tag):
                uid = iso7816Tag.identifier
            default:
                session.invalidate(errorMessage: "Unsupported tag type.")
                self?.continuation?.resume(throwing: NFCError.unsupportedTag)
                self?.continuation = nil
                return
            }

            guard let tagUID = uid, !tagUID.isEmpty else {
                session.invalidate(errorMessage: "Could not read tag UID.")
                self?.continuation?.resume(throwing: NFCError.readFailed("Empty UID"))
                self?.continuation = nil
                return
            }

            // Convert UID bytes to colon-separated hex string
            let hexString = tagUID.map { String(format: "%02X", $0) }.joined(separator: ":")

            session.alertMessage = "FocusBrick detected!"
            session.invalidate()

            DispatchQueue.main.async {
                self?.isScanning = false
            }

            self?.continuation?.resume(returning: hexString)
            self?.continuation = nil
        }
    }
}

// MARK: - Errors

enum NFCError: LocalizedError {
    case notAvailable
    case userCancelled
    case unsupportedTag
    case readFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC is not available on this device. Please enable NFC in Settings."
        case .userCancelled:
            return "NFC scan was cancelled."
        case .unsupportedTag:
            return "This tag type is not supported. Please use an NTAG215 or NTAG216 tag."
        case .readFailed(let reason):
            return "Failed to read NFC tag: \(reason)"
        }
    }
}
