import SwiftUI
import FamilyControls

/// 5-step onboarding flow for first-launch setup.
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            switch viewModel.currentStep {
            case .welcome:
                welcomeStep
            case .screenTimePermission:
                screenTimeStep
            case .pairDevice:
                pairDeviceStep
            case .createMode:
                createModeStep
            case .ready:
                readyStep
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "2E86C1"))

            Text("FocusBrick")
                .font(.system(size: 36, weight: .bold))

            Text("Your phone locks until you physically\nreturn to your FocusBrick.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton(title: "Get Started") {
                viewModel.advance()
            }
        }
        .padding(32)
    }

    // MARK: - Step 2: Screen Time Permission

    private var screenTimeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "2E86C1"))

            Text("Screen Time Access")
                .font(.title)
                .fontWeight(.bold)

            Text("FocusBrick needs Screen Time access to block distracting apps on your iPhone. Your data stays on your device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton(title: "Grant Access") {
                Task { await viewModel.requestScreenTimeAuthorization() }
            }
        }
        .padding(32)
    }

    // MARK: - Step 3: Pair Device

    private var pairDeviceStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "2E86C1"))
                .symbolEffect(.pulse)

            Text("Pair Your FocusBrick")
                .font(.title)
                .fontWeight(.bold)

            Text("Tap your phone to your FocusBrick\nNFC tag to pair it.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton(title: "Scan NFC Tag") {
                Task { await viewModel.pairDevice() }
            }
        }
        .padding(32)
    }

    // MARK: - Step 4: Create First Mode

    private var createModeStep: some View {
        CreateFirstModeView(viewModel: viewModel)
    }

    // MARK: - Step 5: Ready

    private var readyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your FocusBrick is paired and your first\nmode is created. Time to take control.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            PrimaryButton(title: "Start Your First Brick") {
                viewModel.completeOnboarding()
            }
        }
        .padding(32)
    }
}

/// Onboarding step for creating the first mode with FamilyActivityPicker.
struct CreateFirstModeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showActivityPicker = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "app.badge.checkmark.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "2E86C1"))

            Text("Choose Apps to Block")
                .font(.title)
                .fontWeight(.bold)

            Text("Select the apps you want to block\nwhen you Brick your phone.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showActivityPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.app.fill")
                    Text("Select Apps")
                    Spacer()
                    Text("\(activitySelection.applicationTokens.count) selected")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            Spacer()

            PrimaryButton(title: "Create Mode") {
                viewModel.createFirstMode(selection: activitySelection)
            }
            .disabled(activitySelection.applicationTokens.isEmpty)
        }
        .padding(32)
        .familyActivityPicker(
            isPresented: $showActivityPicker,
            selection: $activitySelection
        )
    }
}

/// Reusable primary action button.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "2E86C1"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
