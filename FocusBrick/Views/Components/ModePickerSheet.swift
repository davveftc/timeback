import SwiftUI

/// Sheet for selecting a mode before bricking.
struct ModePickerSheet: View {
    @Binding var selectedMode: Mode?
    let onSelect: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var modes: [Mode] = []

    private let context = PersistenceController.shared.viewContext

    var body: some View {
        NavigationView {
            List(modes) { mode in
                Button {
                    selectedMode = mode
                    dismiss()
                    onSelect()
                } label: {
                    HStack(spacing: 12) {
                        Text(mode.icon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("\(mode.blockedAppTokens.count) apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if selectedMode?.id == mode.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "2E86C1"))
                        }
                    }
                }
            }
            .navigationTitle("Select Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                modes = Mode.fetchAll(in: context)
            }
        }
    }
}
