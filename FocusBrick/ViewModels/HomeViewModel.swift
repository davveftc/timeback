import SwiftUI
import Combine
import FamilyControls

/// Drives the Home screen: brick/unbrick logic, timer state, mode selection.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isBricked = false
    @Published var activeSession: Session?
    @Published var selectedMode: Mode?
    @Published var pairedDevice: Device?
    @Published var isScanning = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showModePicker = false
    @Published var showEmergencySheet = false
    @Published var virtualLockProgress: CGFloat = 0

    private let nfcService: NFCService
    private let blockingService: BlockingService
    private let sessionManager: SessionManager
    private let context = PersistenceController.shared.viewContext
    private var cancellables = Set<AnyCancellable>()

    init(
        nfcService: NFCService = NFCService(),
        blockingService: BlockingService = BlockingService(),
        sessionManager: SessionManager = SessionManager()
    ) {
        self.nfcService = nfcService
        self.blockingService = blockingService
        self.sessionManager = sessionManager

        // Restore state on launch
        restoreState()
    }

    // MARK: - State Restoration

    func restoreState() {
        // Restore active session if shields are still applied
        if let session = sessionManager.restoreActiveSession() {
            activeSession = session
            isBricked = true
        } else {
            isBricked = blockingService.isBricked
        }

        // Load paired device and default mode
        let devices = Device.fetchAll(in: context)
        pairedDevice = devices.first

        if selectedMode == nil {
            selectedMode = Mode.fetchDefault(in: context) ?? Mode.fetchAll(in: context).first
        }
    }

    // MARK: - Brick Flow

    /// Initiate the Brick flow: validate preconditions, scan NFC, apply shields.
    func brick() async {
        // Validate preconditions
        guard let device = pairedDevice else {
            showErrorMessage("Pair a device first.")
            return
        }

        let modes = Mode.fetchAll(in: context)
        guard !modes.isEmpty else {
            showErrorMessage("Create a mode first.")
            return
        }

        // If multiple modes and none selected, show picker
        if modes.count > 1 && selectedMode == nil {
            showModePicker = true
            return
        }

        let mode = selectedMode ?? modes.first!

        guard device.trigger == .nfc else {
            // Phase 2: OTP flow would go here
            return
        }

        // NFC scan
        do {
            isScanning = true
            let scannedUID = try await nfcService.scanTag()
            isScanning = false

            // Validate UID matches paired device
            guard scannedUID == device.nfcUID else {
                showErrorMessage("Unrecognized device.")
                return
            }

            // Apply shields
            blockingService.brick(
                appTokens: mode.blockedAppTokens,
                categoryTokens: mode.blockedCategoryTokens,
                webDomains: mode.blockedWebDomainTokens
            )

            // Create session
            let session = sessionManager.startSession(
                device: device,
                mode: mode,
                triggerType: .nfc
            )

            activeSession = session
            isBricked = true

        } catch let error as NFCError where error == .userCancelled {
            isScanning = false
            // User cancelled — no error to show
        } catch {
            isScanning = false
            showErrorMessage("Scan failed. Try again.")
        }
    }

    // MARK: - Unbrick Flow

    /// Initiate the Unbrick flow: scan NFC, remove shields.
    func unbrick() async {
        guard let device = pairedDevice,
              let session = activeSession
        else { return }

        guard device.trigger == .nfc else {
            // Phase 2: OTP flow
            return
        }

        do {
            isScanning = true
            let scannedUID = try await nfcService.scanTag()
            isScanning = false

            // Must match the device used to brick
            guard scannedUID == session.device?.nfcUID else {
                showErrorMessage("Unrecognized device.")
                return
            }

            // Remove shields
            blockingService.unbrick()

            // End session
            sessionManager.endSession(reason: "nfc_tap")

            activeSession = nil
            isBricked = false

        } catch let error as NFCError where error == .userCancelled {
            isScanning = false
        } catch {
            isScanning = false
            showErrorMessage("Scan failed. Try again.")
        }
    }

    // MARK: - Virtual Lock (F-007)

    /// Activate brick mode without NFC (one-way lock).
    func virtualLock() {
        guard let device = pairedDevice else {
            showErrorMessage("Pair a device first.")
            return
        }

        let modes = Mode.fetchAll(in: context)
        guard !modes.isEmpty else {
            showErrorMessage("Create a mode first.")
            return
        }

        let mode = selectedMode ?? modes.first!

        // Apply shields
        blockingService.brick(
            appTokens: mode.blockedAppTokens,
            categoryTokens: mode.blockedCategoryTokens,
            webDomains: mode.blockedWebDomainTokens
        )

        // Create session marked as virtual lock
        let session = sessionManager.startSession(
            device: device,
            mode: mode,
            triggerType: .nfc,
            isVirtualLock: true
        )

        activeSession = session
        isBricked = true
    }

    // MARK: - Emergency Unbrick (F-006)

    /// Use an emergency unbrick token.
    func emergencyUnbrick() {
        guard let device = pairedDevice else { return }

        let remaining = Int(device.emergencyUnbricksRemaining)
        guard remaining > 0 else { return }

        // Remove shields
        blockingService.unbrick()

        // End session
        sessionManager.endSession(reason: "emergency")

        // Decrement token count in Core Data
        device.emergencyUnbricksRemaining = Int16(remaining - 1)
        PersistenceController.shared.save()

        // Backup to Keychain
        try? KeychainService.setEmergencyCount(remaining - 1, for: device.deviceUID)

        activeSession = nil
        isBricked = false
    }

    var emergencyUnbricksRemaining: Int {
        Int(pairedDevice?.emergencyUnbricksRemaining ?? 0)
    }

    // MARK: - Helpers

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// Make NFCError equatable for pattern matching
extension NFCError: Equatable {
    static func == (lhs: NFCError, rhs: NFCError) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailable, .notAvailable),
             (.userCancelled, .userCancelled),
             (.unsupportedTag, .unsupportedTag):
            return true
        case (.readFailed(let a), .readFailed(let b)):
            return a == b
        default:
            return false
        }
    }
}
