import SwiftUI
import FamilyControls

/// Create or edit a mode: name, emoji icon, and blocked apps via FamilyActivityPicker.
struct ModeEditorView: View {
    let mode: Mode?
    @ObservedObject var viewModel: ModeViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var selectedIcon: String
    @State private var activitySelection: FamilyActivitySelection
    @State private var showActivityPicker = false

    init(mode: Mode?, viewModel: ModeViewModel) {
        self.mode = mode
        self.viewModel = viewModel
        _name = State(initialValue: mode?.name ?? "")
        _selectedIcon = State(initialValue: mode?.icon ?? "💼")
        _activitySelection = State(initialValue: mode?.familyActivitySelection ?? FamilyActivitySelection())
    }

    var isEditing: Bool { mode != nil }
    var title: String { isEditing ? "Edit Mode" : "New Mode" }

    var body: some View {
        NavigationView {
            Form {
                // Name
                Section("Name") {
                    TextField("Mode name", text: $name)
                        .onChange(of: name) { newValue in
                            if newValue.count > Mode.maxNameLength {
                                name = String(newValue.prefix(Mode.maxNameLength))
                            }
                        }
                }

                // Icon picker
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Mode.availableIcons, id: \.self) { icon in
                            Text(icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(
                                    selectedIcon == icon
                                        ? Color(hex: "2E86C1").opacity(0.2)
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedIcon == icon ? Color(hex: "2E86C1") : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // App selection
                Section("Apps to Block") {
                    Button {
                        showActivityPicker = true
                    } label: {
                        HStack {
                            Text("Select Apps")
                            Spacer()
                            Text("\(activitySelection.applicationTokens.count) selected")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .familyActivityPicker(
                isPresented: $showActivityPicker,
                selection: $activitySelection
            )
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let mode = mode {
            viewModel.updateMode(mode, name: trimmed, icon: selectedIcon, selection: activitySelection)
        } else {
            viewModel.createMode(name: trimmed, icon: selectedIcon, selection: activitySelection)
        }
        dismiss()
    }
}
