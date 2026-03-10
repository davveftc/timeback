import SwiftUI

/// The main screen with two states: Unbricked and Bricked.
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background
            if viewModel.isBricked {
                Color(hex: "1C2833")
                    .ignoresSafeArea()
            }

            if viewModel.isBricked {
                brickedState
            } else {
                unbrickedState
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isBricked)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showModePicker) {
            ModePickerSheet(selectedMode: $viewModel.selectedMode) {
                Task { await viewModel.brick() }
            }
        }
        .sheet(isPresented: $viewModel.showEmergencySheet) {
            EmergencyUnbrickSheet(
                remainingTokens: viewModel.emergencyUnbricksRemaining,
                onConfirm: { viewModel.emergencyUnbrick() }
            )
        }
        .onAppear {
            viewModel.restoreState()
        }
    }

    // MARK: - Unbricked State

    private var unbrickedState: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("FocusBrick")
                    .font(.system(size: 24, weight: .bold))

                Spacer()

                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Device status pill
            if let device = viewModel.pairedDevice {
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("\(device.name) \u{2022} Connected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color(.systemGray6)))
                .padding(.top, 8)
            }

            Spacer()

            // Mode selector
            if let mode = viewModel.selectedMode {
                Button {
                    viewModel.showModePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(mode.icon)
                        Text(mode.name)
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                }
                .padding(.bottom, 16)
            }

            // Brick button
            BrickButtonView(
                icon: viewModel.selectedMode?.icon ?? "🧱",
                isEnabled: viewModel.pairedDevice != nil,
                onTap: {
                    Task { await viewModel.brick() }
                },
                onLongPress: {
                    viewModel.virtualLock()
                }
            )

            if viewModel.pairedDevice == nil {
                Text("Pair a device to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            } else {
                Text("Tap to Brick")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 12)
            }

            Spacer()
        }
        .navigationBarHidden(true)
    }

    // MARK: - Bricked State

    private var brickedState: some View {
        VStack(spacing: 0) {
            Spacer()

            // Mode icon + name
            if let mode = viewModel.activeSession?.mode {
                HStack(spacing: 6) {
                    Text(mode.icon)
                    Text(mode.name)
                        .font(.system(size: 18))
                }
                .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            // Focus timer
            if let session = viewModel.activeSession {
                FocusTimerView(startDate: session.startedAt)
            }

            Text("Your phone is Bricked")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)

            Spacer()

            // Unbrick button
            Button {
                Task { await viewModel.unbrick() }
            } label: {
                Text("Unbrick")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white, lineWidth: 2)
                    )
            }
            .padding(.horizontal, 32)

            // Emergency unbrick
            Button {
                viewModel.showEmergencySheet = true
            } label: {
                Text("Emergency Unbrick")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            .opacity(viewModel.emergencyUnbricksRemaining > 0 ? 1 : 0)

            if viewModel.emergencyUnbricksRemaining <= 0 {
                Text("No emergency unbricks remaining.\nUse your FocusBrick device.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
        }
    }
}
