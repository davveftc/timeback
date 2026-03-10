import SwiftUI
import FamilyControls

/// CRUD operations for Modes. Drives ModeListView and ModeEditorView.
@MainActor
final class ModeViewModel: ObservableObject {
    @Published var modes: [Mode] = []
    @Published var errorMessage: String?
    @Published var showError = false

    private let context = PersistenceController.shared.viewContext

    init() {
        fetchModes()
    }

    func fetchModes() {
        modes = Mode.fetchAll(in: context)
    }

    var canCreateMode: Bool {
        modes.count < Mode.maxModes
    }

    /// Create a new mode.
    @discardableResult
    func createMode(
        name: String,
        icon: String,
        selection: FamilyActivitySelection,
        isDefault: Bool = false
    ) -> Mode? {
        guard canCreateMode else {
            errorMessage = "Maximum 10 modes reached."
            showError = true
            return nil
        }

        let trimmed = String(name.prefix(Mode.maxNameLength))
        guard !trimmed.isEmpty else {
            errorMessage = "Mode name is required."
            showError = true
            return nil
        }

        // If this is the first mode, make it default
        let shouldBeDefault = isDefault || modes.isEmpty

        let mode = Mode.create(
            name: trimmed,
            icon: icon,
            selection: selection,
            isDefault: shouldBeDefault,
            in: context
        )
        PersistenceController.shared.save()
        fetchModes()
        return mode
    }

    /// Update an existing mode.
    func updateMode(
        _ mode: Mode,
        name: String? = nil,
        icon: String? = nil,
        selection: FamilyActivitySelection? = nil
    ) {
        if let name = name {
            mode.name = String(name.prefix(Mode.maxNameLength))
        }
        if let icon = icon {
            mode.icon = icon
        }
        if let selection = selection {
            mode.familyActivitySelection = selection
        }
        mode.updatedAt = Date()
        PersistenceController.shared.save()
        fetchModes()
    }

    /// Delete a mode. Returns false if the mode is currently active.
    func deleteMode(_ mode: Mode, activeSession: Session?) -> Bool {
        // Cannot delete a mode that is currently active in a Brick session
        if let session = activeSession, session.mode?.id == mode.id {
            errorMessage = "Cannot delete a mode that is currently active."
            showError = true
            return false
        }

        // If deleting the default mode, promote another
        if mode.isDefault, let next = modes.first(where: { $0.id != mode.id }) {
            next.isDefault = true
        }

        context.delete(mode)
        PersistenceController.shared.save()
        fetchModes()
        return true
    }

    /// Set a mode as the default.
    func setDefault(_ mode: Mode) {
        // Clear existing default
        for m in modes {
            m.isDefault = (m.id == mode.id)
        }
        PersistenceController.shared.save()
        fetchModes()
    }
}
