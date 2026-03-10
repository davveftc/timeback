import SwiftUI

/// List of modes with create, edit, delete, and set-default actions.
struct ModeListView: View {
    @StateObject private var viewModel = ModeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showEditor = false
    @State private var editingMode: Mode?

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.modes) { mode in
                    ModeRow(mode: mode, isDefault: mode.isDefault)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !appState.isBricked {
                                editingMode = mode
                                showEditor = true
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !appState.isBricked {
                                Button(role: .destructive) {
                                    _ = viewModel.deleteMode(mode, activeSession: appState.activeSession)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if !mode.isDefault && !appState.isBricked {
                                Button {
                                    viewModel.setDefault(mode)
                                } label: {
                                    Label("Default", systemImage: "star.fill")
                                }
                                .tint(.orange)
                            }
                        }
                }

                if viewModel.modes.isEmpty {
                    Text("No modes created yet.\nTap + to create your first mode.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Modes")
            .toolbar {
                if !appState.isBricked && viewModel.canCreateMode {
                    Button {
                        editingMode = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                ModeEditorView(
                    mode: editingMode,
                    viewModel: viewModel
                )
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.fetchModes()
            }
        }
    }
}

struct ModeRow: View {
    let mode: Mode
    let isDefault: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(mode.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(mode.name)
                        .font(.headline)
                    if isDefault {
                        Text("Default")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "2E86C1").opacity(0.15))
                            .foregroundColor(Color(hex: "2E86C1"))
                            .clipShape(Capsule())
                    }
                }

                Text("\(mode.blockedAppTokens.count) apps blocked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
