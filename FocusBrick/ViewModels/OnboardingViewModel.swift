import SwiftUI
import FamilyControls

/// Tracks onboarding progress across 5 steps.
/// Persists progress so users resume from the last incomplete step after a force-quit.
@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case screenTimePermission = 1
        case pairDevice = 2
        case createMode = 3
        case ready = 4
    }

    @Published var currentStep: Step = .welcome
    @Published var isAuthorized = false
    @Published var isPaired = false
    @Published var isModeCreated = false
    @Published var errorMessage: String?
    @Published var showError = false

    @AppStorage("onboarding_step") private var savedStep = 0
    @AppStorage("isOnboardingComplete") var isOnboardingComplete = false

    private let nfcService = NFCService()
    private let context = PersistenceController.shared.viewContext

    init() {
        // Resume from saved step
        currentStep = Step(rawValue: savedStep) ?? .welcome

        // Check if already authorized
        checkAuthorization()
    }

    func checkAuthorization() {
        let center = AuthorizationCenter.shared
        isAuthorized = (center.authorizationStatus == .approved)
    }

    // MARK: - Step 2: Screen Time Permission

    func requestScreenTimeAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            advance()
        } catch {
            errorMessage = "Screen Time access is required. Please grant access to continue."
            showError = true
        }
    }

    // MARK: - Step 3: Pair Device

    func pairDevice() async -> Device? {
        do {
            let uid = try await nfcService.scanTag()

            // Check if already paired
            if Device.findByNfcUID(uid, in: context) != nil {
                errorMessage = "This device is already paired."
                showError = true
                return nil
            }

            let device = Device.create(
                name: "My FocusBrick",
                triggerType: .nfc,
                nfcUID: uid,
                in: context
            )
            PersistenceController.shared.save()

            // Backup emergency count to Keychain
            try? KeychainService.setEmergencyCount(5, for: device.deviceUID)

            isPaired = true
            advance()
            return device
        } catch let error as NFCError where error == .userCancelled {
            return nil
        } catch {
            errorMessage = "Failed to read NFC tag. Try again."
            showError = true
            return nil
        }
    }

    // MARK: - Step 4: Create First Mode

    func createFirstMode(
        name: String = "Focus",
        icon: String = "🎯",
        selection: FamilyActivitySelection
    ) {
        let _ = Mode.create(
            name: name,
            icon: icon,
            selection: selection,
            isDefault: true,
            in: context
        )
        PersistenceController.shared.save()
        isModeCreated = true
        advance()
    }

    // MARK: - Navigation

    func advance() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        currentStep = nextStep
        savedStep = nextStep.rawValue
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        savedStep = 0
    }

    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .screenTimePermission: return isAuthorized
        case .pairDevice: return isPaired
        case .createMode: return isModeCreated
        case .ready: return true
        }
    }
}
