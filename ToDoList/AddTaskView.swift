import SwiftUI

struct AddTaskView: View {
    @Binding var newTitle: String
    @Binding var dueDate: Date?
    var onAdd: (String, Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isDueEnabled: Bool = false
    @State private var localDueDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Task")) {
                    TextField("Task title", text: $newTitle)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                    Toggle("Set due date", isOn: $isDueEnabled)
                    if isDueEnabled {
                        DatePicker("Due", selection: $localDueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let selectedDueDate = isDueEnabled ? localDueDate : nil
                        onAdd(trimmed, selectedDueDate)
                        dismiss()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let due = dueDate {
                    localDueDate = due
                    isDueEnabled = true
                } else {
                    isDueEnabled = false
                    localDueDate = Date()
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var title: String = ""
        @State private var due: Date? = nil

        var body: some View {
            AddTaskView(newTitle: $title, dueDate: $due) { t, d in
                print("Added: \(t) due: \(String(describing: d))")
            }
        }
    }
    PreviewWrapper()
}
