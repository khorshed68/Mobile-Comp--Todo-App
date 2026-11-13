import SwiftUI

// Add o Edit dutor jonnoi ei form use hoy
struct TaskFormView: View {
    @Environment(\.dismiss) private var dismiss

    let screenTitle: String
    let onSave: (String, String) -> Void

    @State private var title: String
    @State private var description: String

    init(screenTitle: String,
         initialTitle: String = "",
         initialDescription: String = "",
         onSave: @escaping (String, String) -> Void) {
        self.screenTitle = screenTitle
        self.onSave = onSave
        _title = State(initialValue: initialTitle)
        _description = State(initialValue: initialDescription)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Task title", text: $title)
                }
                Section(header: Text("Description")) {
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(screenTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let d = description.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(t, d)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
