import SwiftUI

/// Settings screen: paired devices, about info.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var devices: [Device] = []
    @State private var showUnpairAlert = false
    @State private var deviceToUnpair: Device?

    private let context = PersistenceController.shared.viewContext

    var body: some View {
        List {
            // Paired Devices
            Section("Paired Devices") {
                if devices.isEmpty {
                    Text("No devices paired.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(devices) { device in
                        NavigationLink {
                            DeviceDetailView(device: device) {
                                loadDevices()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "wave.3.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "2E86C1"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(.headline)
                                    Text(device.trigger == .nfc ? "NFC" : "OTP Token")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            // Appearance (placeholder for future)
            Section("Appearance") {
                Text("Coming soon")
                    .foregroundColor(.secondary)
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadDevices() }
    }

    private func loadDevices() {
        devices = Device.fetchAll(in: context)
    }
}

/// Detail view for a paired device showing UID, emergency tokens, and unpair option.
struct DeviceDetailView: View {
    let device: Device
    let onUnpair: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showUnpairAlert = false

    private let context = PersistenceController.shared.viewContext

    // Check if currently bricked (simplified check)
    private var isBricked: Bool {
        Session.fetchActive(in: context) != nil
    }

    var body: some View {
        List {
            Section("Device Info") {
                LabeledContent("Name", value: device.name)
                LabeledContent("Type", value: device.trigger == .nfc ? "NFC" : "OTP Token")
                if let uid = device.nfcUID {
                    LabeledContent("UID", value: uid)
                }
                LabeledContent("Paired", value: device.pairedAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Emergency Unbricks") {
                HStack {
                    Text("Remaining")
                    Spacer()
                    Text("\(device.emergencyTokens) of 5")
                        .foregroundColor(device.emergencyTokens > 0 ? .primary : .red)
                }
            }

            Section {
                Button(role: .destructive) {
                    showUnpairAlert = true
                } label: {
                    Text("Unpair Device")
                }
                .disabled(isBricked)

                if isBricked {
                    Text("Cannot unpair while Bricked.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Unpair Device?", isPresented: $showUnpairAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Unpair", role: .destructive) {
                unpairDevice()
            }
        } message: {
            Text("Are you sure? You will need to re-pair this device.")
        }
    }

    private func unpairDevice() {
        context.delete(device)
        PersistenceController.shared.save()
        onUnpair()
        dismiss()
    }
}
